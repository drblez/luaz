#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ftp_sync_src.sh --pds HLQ.PDS --root <dir> [--host H] [--port P] [--user U] [--pass W] [--map FILE]
                 [--rewrite-includes-map FILE] [--recfm R] [--lrecl N] [--blksize N]
                 [--use-map] [--ext .jcl]...

Defaults:
  --root .
  --host from MF_HOST or 192.168.1.160
  --port from MF_PORT or 2121
  --user from MF_USER
  --pass from MF_PASS
  --map  ./pds-map.txt
  --rewrite-includes-map  (optional) rewrite quoted includes to PDS member names during export
  --recfm  (default FB)
  --lrecl  (default 80)
  --blksize (default 0)
  --use-map  (use existing CSV map as input; only upload listed files)
  --ext  (repeatable; limit files by extension, e.g. --ext .jcl)

Notes:
  - Uses FILETYPE=SEQ with RECFM/LRECL/BLKSIZE as provided.
  - Member names are derived from basename, uppercased, non-alnum => '_', truncated to 8.
  - Collisions are resolved with a 2-hex suffix (first 6 + suffix).
  - When --rewrite-includes-map is provided, files are staged to a temp dir and rewritten before upload.
USAGE
}

HOST="${MF_HOST:-192.168.1.160}"
PORT="${MF_PORT:-2121}"
USER="${MF_USER:-}"
PASS="${MF_PASS:-}"
ROOT="."
PDS=""
MAP="./pds-map.txt"
REWRITE_MAP=""
RECFM="FB"
LRECL="80"
BLKSIZE="0"
USE_MAP="no"
EXTS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pds) PDS="$2"; shift 2;;
    --root) ROOT="$2"; shift 2;;
    --host) HOST="$2"; shift 2;;
    --port) PORT="$2"; shift 2;;
    --user) USER="$2"; shift 2;;
    --pass) PASS="$2"; shift 2;;
    --map) MAP="$2"; shift 2;;
    --rewrite-includes-map) REWRITE_MAP="$2"; shift 2;;
    --recfm) RECFM="$2"; shift 2;;
    --lrecl) LRECL="$2"; shift 2;;
    --blksize) BLKSIZE="$2"; shift 2;;
    --use-map) USE_MAP="yes"; shift 1;;
    --ext) EXTS+=("$2"); shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

if [[ -z "$PDS" ]]; then
  echo "Missing --pds" >&2
  usage
  exit 1
fi
if [[ -z "$USER" || -z "$PASS" ]]; then
  echo "Missing MF_USER/MF_PASS or --user/--pass" >&2
  exit 1
fi
if [[ ! -d "$ROOT" ]]; then
  echo "Root dir not found: $ROOT" >&2
  exit 1
fi

STAGE_ROOT="$ROOT"
STAGE_DIR=""
TMP_FTP=""

cleanup() {
  [[ -n "$TMP_FTP" && -f "$TMP_FTP" ]] && rm -f "$TMP_FTP"
  [[ -n "$STAGE_DIR" && -d "$STAGE_DIR" ]] && rm -rf "$STAGE_DIR"
}
trap cleanup EXIT

if [[ -n "$REWRITE_MAP" ]]; then
  if [[ ! -f "$REWRITE_MAP" ]]; then
    echo "Rewrite map not found: $REWRITE_MAP" >&2
    exit 1
  fi
  STAGE_DIR="$(mktemp -d)"
  cp -R "$ROOT"/. "$STAGE_DIR"/
  scripts/rewrite_includes.py --map "$REWRITE_MAP" --root "$STAGE_DIR" >/dev/null
  STAGE_ROOT="$STAGE_DIR"
fi

TMP_FTP="$(mktemp)"

python3 - <<'PY' "$ROOT" "$STAGE_ROOT" "$PDS" "$MAP" "$TMP_FTP" "$RECFM" "$LRECL" "$BLKSIZE" "$USE_MAP" "${EXTS[@]:-}"
import os, re, sys, binascii
orig_root, stage_root, pds, map_path, ftp_path, recfm, lrecl, blksize, use_map, *exts = sys.argv[1:]

files = []
orig_root = os.path.normpath(orig_root)
stage_root = os.path.normpath(stage_root)
exts = [e.lower() for e in exts if e]

map_entries = []
if use_map == "yes" and os.path.exists(map_path):
    import csv
    with open(map_path, newline='', encoding='utf-8') as f:
        rd = csv.DictReader(f)
        for row in rd:
            rel = row['relative_path']
            mem = row['member']
            rel_norm = os.path.normpath(rel)
            if not rel_norm.startswith(orig_root + os.sep) and rel_norm != orig_root:
                continue
            rel_tail = rel_norm[len(orig_root) + 1:] if rel_norm.startswith(orig_root + os.sep) else ""
            if exts and os.path.splitext(rel_tail)[1].lower() not in exts:
                continue
            map_entries.append((rel_tail, mem))
else:
    for base, _, names in os.walk(stage_root):
        for n in names:
            p = os.path.join(base, n)
            if os.path.isfile(p):
                if exts and os.path.splitext(p)[1].lower() not in exts:
                    continue
                files.append(p)
    files.sort()

seen = {}

def to_member(path):
    base = os.path.basename(path)
    base = os.path.splitext(base)[0]
    base = re.sub(r'[^A-Za-z0-9]', '_', base).upper()
    base = base[:8] if base else 'NONAME'
    mem = base
    if mem in seen:
        h = binascii.crc32(path.encode('utf-8')) & 0xFF
        mem = (base[:6] + f"{h:02X}")[:8]
    seen[mem] = path
    return mem

write_map = use_map != "yes"
if write_map:
    m = open(map_path, 'w', encoding='utf-8')
    m.write('relative_path,member\n')
else:
    m = None
with open(ftp_path, 'w', encoding='utf-8') as f:
    f.write(f"user {os.environ.get('MF_USER','')} {os.environ.get('MF_PASS','')}\n")
    f.write('passive\n')
    f.write('epsv4\n')
    f.write('quote SITE FILETYPE=SEQ\n')
    f.write(f"quote SITE LRECL={lrecl} RECFM={recfm} BLKSIZE={blksize}\n")
    if use_map == "yes":
        for rel_tail, mem in map_entries:
            p = os.path.join(stage_root, rel_tail) if rel_tail else stage_root
            if not os.path.exists(p):
                raise SystemExit(f"missing file for map entry: {p}")
            f.write(f"put \"{p}\" '{pds}({mem})'\n")
    else:
        for p in files:
            rel = os.path.relpath(p, stage_root)
            mem = to_member(rel)
            if write_map:
                m.write(f"{rel},{mem}\n")
            f.write(f"put \"{p}\" '{pds}({mem})'\n")
    f.write('bye\n')
if m is not None:
    m.close()
PY

ftp -inv "$HOST" "$PORT" <"$TMP_FTP"

echo "Uploaded to $PDS"
echo "Map: $MAP"
