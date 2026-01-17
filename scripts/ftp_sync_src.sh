#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ftp_sync_src.sh --pds HLQ.PDS --root <dir> [--host H] [--port P] [--user U] [--pass W] [--map FILE]

Defaults:
  --root .
  --host from MF_HOST or 192.168.1.160
  --port from MF_PORT or 2121
  --user from MF_USER
  --pass from MF_PASS
  --map  ./pds-map.txt

Notes:
  - Uses FILETYPE=SEQ with RECFM=FB LRECL=80 (matches DRBLEZ.LUA.SRC).
  - Member names are derived from basename, uppercased, non-alnum => '_', truncated to 8.
  - Collisions are resolved with a 2-hex suffix (first 6 + suffix).
USAGE
}

HOST="${MF_HOST:-192.168.1.160}"
PORT="${MF_PORT:-2121}"
USER="${MF_USER:-}"
PASS="${MF_PASS:-}"
ROOT="."
PDS=""
MAP="./pds-map.txt"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pds) PDS="$2"; shift 2;;
    --root) ROOT="$2"; shift 2;;
    --host) HOST="$2"; shift 2;;
    --port) PORT="$2"; shift 2;;
    --user) USER="$2"; shift 2;;
    --pass) PASS="$2"; shift 2;;
    --map) MAP="$2"; shift 2;;
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

TMP_FTP="$(mktemp)"
trap 'rm -f "$TMP_FTP"' EXIT

python3 - <<'PY' "$ROOT" "$PDS" "$MAP" "$TMP_FTP"
import os, re, sys, binascii
root, pds, map_path, ftp_path = sys.argv[1:]

files = []
for base, _, names in os.walk(root):
    for n in names:
        p = os.path.join(base, n)
        if os.path.isfile(p):
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

with open(map_path, 'w', encoding='utf-8') as m, open(ftp_path, 'w', encoding='utf-8') as f:
    m.write('relative_path,member\n')
    f.write(f"user {os.environ.get('MF_USER','')} {os.environ.get('MF_PASS','')}\n")
    f.write('passive\n')
    f.write('epsv4\n')
    f.write('quote SITE FILETYPE=SEQ\n')
    f.write('quote SITE LRECL=80 RECFM=FB BLKSIZE=0\n')
    for p in files:
        rel = os.path.relpath(p, root)
        mem = to_member(p)
        m.write(f"{rel},{mem}\n")
        f.write(f"put \"{p}\" '{pds}({mem})'\n")
    f.write('bye\n')
PY

ftp -inv "$HOST" "$PORT" <"$TMP_FTP"

echo "Uploaded to $PDS"
echo "Map: $MAP"
