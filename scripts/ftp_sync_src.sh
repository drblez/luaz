#!/usr/bin/env bash
# Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
#
# Sync local sources to a z/OS PDS via FTP.
#
# Object Table:
# | Object | Kind | Purpose |
# |--------|------|---------|
# | ftp_sync_src.sh | script | Upload files from a directory to a PDS |
# | usage | function | Print CLI help |
# | cleanup | function | Remove temp files/dirs |
#
# Notes:
# - Supports staging (copy + include rewrites) before upload.
# - Automatically formats HLASM sources before upload:
#   - replace TAB with spaces
#   - wrap long `* ...` comment records
#   - move long trailing remarks (after opcode) to `* ...` records above
#
set -euo pipefail

# Load optional repo-local environment (.env) with MF_* defaults.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  . "$ENV_FILE"
  set +a
fi

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
  --map  (auto: pds-map-*.csv based on --root when present; else ./pds-map.txt)
  --rewrite-includes-map  (auto: pds-map-inc.csv when present)
  --recfm/--lrecl  (auto by file type if not provided)
     - .c/.h/.inc => VB/1024
     - .asm/.jcl/.lua/.rexx => FB/80
     - default => FB/80
  --blksize (default 0)
  --use-map  (auto: use existing CSV map when present; otherwise generate)
  --ext  (repeatable; limit files by extension, e.g. --ext .jcl)

Notes:
  - Uses FILETYPE=SEQ with RECFM/LRECL/BLKSIZE as provided.
  - Member names are derived from basename, uppercased, non-alnum => '_', truncated to 8.
  - Collisions are resolved with a 2-hex suffix (first 6 + suffix).
  - Include rewrites are enabled by default when C/INC/H files are present and pds-map-inc.csv exists.
USAGE
}

HOST="${MF_HOST:-192.168.1.160}"
PORT="${MF_PORT:-2121}"
USER="${MF_USER:-}"
PASS="${MF_PASS:-}"
ROOT="."
PDS=""
MAP=""
MAP_SET="no"
REWRITE_MAP=""
REWRITE_SET="no"
RECFM=""
LRECL=""
BLKSIZE=""
RECFM_SET="no"
LRECL_SET="no"
BLKSIZE_SET="no"
USE_MAP=""
USE_MAP_SET="no"
EXTS=()
AUTO_REWRITE="no"
AUTO_ASMFMT="no"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pds) PDS="$2"; shift 2;;
    --root) ROOT="$2"; shift 2;;
    --host) HOST="$2"; shift 2;;
    --port) PORT="$2"; shift 2;;
    --user) USER="$2"; shift 2;;
    --pass) PASS="$2"; shift 2;;
    --map) MAP="$2"; MAP_SET="yes"; shift 2;;
    --rewrite-includes-map) REWRITE_MAP="$2"; REWRITE_SET="yes"; shift 2;;
    --recfm) RECFM="$2"; RECFM_SET="yes"; shift 2;;
    --lrecl) LRECL="$2"; LRECL_SET="yes"; shift 2;;
    --blksize) BLKSIZE="$2"; BLKSIZE_SET="yes"; shift 2;;
    --use-map) USE_MAP="yes"; USE_MAP_SET="yes"; shift 1;;
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

detect_map_defaults() {
  local root_norm
  local base
  local candidate=""
  root_norm="${ROOT%/}"
  base="$(basename "$root_norm")"
  if [[ "$MAP_SET" != "yes" ]]; then
    if [[ -z "$MAP" && ${#EXTS[@]} -gt 0 ]]; then
      for ext in "${EXTS[@]}"; do
        case "$ext" in
          .asm) MAP="pds-map-asm.csv"; break ;;
          .jcl) MAP="pds-map-jcl.csv"; break ;;
          .inc|.h) MAP="pds-map-inc.csv"; break ;;
          .c) MAP="pds-map-src.csv"; break ;;
          .lua) MAP="pds-map-lua.csv"; break ;;
          .rexx|.rex) MAP="pds-map-rexx.csv"; break ;;
        esac
      done
    fi
    if [[ -z "$MAP" ]]; then
      if [[ "$root_norm" == *"/tests/integration/lua" ]]; then
        candidate="pds-map-test.csv"
      fi
      case "$base" in
        src) candidate="pds-map-src.csv" ;;
        include) candidate="pds-map-inc.csv" ;;
        jcl) candidate="pds-map-jcl.csv" ;;
        lua) candidate="${candidate:-pds-map-lua.csv}" ;;
        rexx) candidate="pds-map-rexx.csv" ;;
        *) candidate="" ;;
      esac
      if [[ -n "$candidate" ]]; then
        MAP="$candidate"
      fi
    fi
  fi
  if [[ -z "$MAP" ]]; then
    MAP="./pds-map.txt"
  fi
  if [[ "$USE_MAP_SET" != "yes" ]]; then
    if [[ -f "$MAP" ]]; then
      USE_MAP="yes"
    else
      USE_MAP="no"
    fi
  fi
}

detect_map_defaults

if [[ -z "$REWRITE_MAP" ]]; then
  for ext in "${EXTS[@]:-}"; do
    if [[ "$ext" == ".c" || "$ext" == ".h" || "$ext" == ".inc" ]]; then
      AUTO_REWRITE="yes"
      break
    fi
  done
  if [[ "$AUTO_REWRITE" != "yes" && ${#EXTS[@]} -eq 0 ]]; then
    if find "$ROOT" -type f \( -name '*.c' -o -name '*.h' -o -name '*.inc' \) -print -quit | rg -q .; then
      AUTO_REWRITE="yes"
    fi
  fi
  if [[ "$AUTO_REWRITE" == "yes" ]]; then
    if [[ -f "pds-map-inc.csv" ]]; then
      REWRITE_MAP="pds-map-inc.csv"
    else
      echo "Rewrite map not found: pds-map-inc.csv" >&2
      exit 1
    fi
  fi
fi

detect_defaults() {
  local has_vb="no"
  local has_fb="no"
  local desired_mode=""
  if [[ ${#EXTS[@]} -gt 0 ]]; then
    for ext in "${EXTS[@]}"; do
      case "$ext" in
        .c|.h|.inc) has_vb="yes" ;;
        .asm|.jcl|.lua|.rexx|.rex) has_fb="yes" ;;
      esac
    done
  else
    if find "$ROOT" -type f \( -name '*.c' -o -name '*.h' -o -name '*.inc' \) -print -quit | rg -q .; then
      has_vb="yes"
    fi
    if find "$ROOT" -type f \( -name '*.asm' -o -name '*.jcl' -o -name '*.lua' -o -name '*.rexx' -o -name '*.rex' \) -print -quit | rg -q .; then
      has_fb="yes"
    fi
  fi
  if [[ "$has_vb" == "yes" ]]; then
    desired_mode="VB"
  elif [[ "$has_fb" == "yes" ]]; then
    desired_mode="FB"
  else
    desired_mode="FB"
  fi
  if [[ "$RECFM_SET" != "yes" ]]; then
    RECFM="$desired_mode"
  fi
  if [[ "$LRECL_SET" != "yes" ]]; then
    if [[ "$RECFM" == "VB" ]]; then
      LRECL="1024"
    else
      LRECL="80"
    fi
  fi
  if [[ "$BLKSIZE_SET" != "yes" ]]; then
    BLKSIZE="0"
  fi
}

detect_defaults

for ext in "${EXTS[@]:-}"; do
  if [[ "$ext" == ".asm" ]]; then
    AUTO_ASMFMT="yes"
    break
  fi
done
if [[ "$AUTO_ASMFMT" != "yes" && ${#EXTS[@]} -eq 0 ]]; then
  if find "$ROOT" -type f -name '*.asm' -print -quit | rg -q .; then
    AUTO_ASMFMT="yes"
  fi
fi

STAGE_ROOT="$ROOT"
STAGE_DIR=""
TMP_FTP=""

cleanup() {
  [[ -n "$TMP_FTP" && -f "$TMP_FTP" ]] && rm -f "$TMP_FTP"
  [[ -n "$STAGE_DIR" && -d "$STAGE_DIR" ]] && rm -rf "$STAGE_DIR"
}
trap cleanup EXIT

if [[ -n "$REWRITE_MAP" || "$AUTO_ASMFMT" == "yes" ]]; then
  if [[ ! -f "$REWRITE_MAP" ]]; then
    if [[ -n "$REWRITE_MAP" ]]; then
      echo "Rewrite map not found: $REWRITE_MAP" >&2
      exit 1
    fi
  fi
  STAGE_DIR="$(mktemp -d)"
  cp -R "$ROOT"/. "$STAGE_DIR"/
  if [[ -n "$REWRITE_MAP" ]]; then
    scripts/rewrite_includes.py --map "$REWRITE_MAP" --root "$STAGE_DIR" >/dev/null
  fi
  if [[ "$AUTO_ASMFMT" == "yes" ]]; then
    python3 scripts/asmfmt.py --root "$STAGE_DIR" --ext .asm --quiet
  fi
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
            if orig_root in (".", ""):
                rel_tail = rel_norm
            else:
                rel_tail = rel_norm[len(orig_root) + 1:] if rel_norm.startswith(orig_root + os.sep) else rel_norm
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
