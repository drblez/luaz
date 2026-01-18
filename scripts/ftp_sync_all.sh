#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ftp_sync_all.sh [--hlq HLQ] [--host H] [--port P] [--user U] [--pass W]

Defaults:
  HLQ from MF_HLQ or DRBLEZ
  host/port/user/pass from MF_HOST/MF_PORT/MF_USER/MF_PASS

Uploads:
  SRC  -> HLQ.LUA.SRC  (src/, lua-vm/src/)
  INC  -> HLQ.LUA.INC  (include/, lua-vm/src/*.h)
  LUA  -> HLQ.LUA.LUA  (lua/)
  JCL  -> HLQ.LUA.JCL  (jcl/)

Notes:
  - Uses rewrite-includes during export for SRC/INC to map to PDS member names.
  - Requires pds-map-src.csv and pds-map-inc.csv in repo root.
USAGE
}

HLQ="${MF_HLQ:-DRBLEZ}"
HOST="${MF_HOST:-192.168.1.160}"
PORT="${MF_PORT:-2121}"
USER="${MF_USER:-}"
PASS="${MF_PASS:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hlq) HLQ="$2"; shift 2;;
    --host) HOST="$2"; shift 2;;
    --port) PORT="$2"; shift 2;;
    --user) USER="$2"; shift 2;;
    --pass) PASS="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
 done

if [[ -z "$USER" || -z "$PASS" ]]; then
  echo "Missing MF_USER/MF_PASS or --user/--pass" >&2
  exit 1
fi

if [[ ! -f pds-map-src.csv || ! -f pds-map-inc.csv ]]; then
  echo "Missing pds-map-src.csv or pds-map-inc.csv. Run scripts/pds_map.py first." >&2
  exit 1
fi

export MF_HOST="$HOST" MF_PORT="$PORT" MF_USER="$USER" MF_PASS="$PASS"

# SRC/INC: VB/1024, LUA/JCL: FB/80
scripts/ftp_sync_src.sh --pds "$HLQ.LUA.SRC" --root src --map pds-map-src.csv --use-map --rewrite-includes-map pds-map-inc.csv --recfm VB --lrecl 1024
scripts/ftp_sync_src.sh --pds "$HLQ.LUA.SRC" --root lua-vm/src --map pds-map-src.csv --use-map --rewrite-includes-map pds-map-inc.csv --recfm VB --lrecl 1024
scripts/ftp_sync_src.sh --pds "$HLQ.LUA.INC" --root include --map pds-map-inc.csv --use-map --rewrite-includes-map pds-map-inc.csv --recfm VB --lrecl 1024
scripts/ftp_sync_src.sh --pds "$HLQ.LUA.INC" --root lua-vm/src --map pds-map-inc.csv --use-map --rewrite-includes-map pds-map-inc.csv --recfm VB --lrecl 1024
scripts/ftp_sync_src.sh --pds "$HLQ.LUA.LUA" --root lua --recfm FB --lrecl 80
scripts/ftp_sync_src.sh --pds "$HLQ.LUA.JCL" --root jcl --recfm FB --lrecl 80

echo "Done. Uploaded SRC/INC/LUA/JCL to $HLQ.LUA.*"
