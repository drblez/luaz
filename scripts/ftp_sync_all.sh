#!/usr/bin/env bash
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
  ftp_sync_all.sh [--hlq HLQ] [--host H] [--port P] [--user U] [--pass W] [--debug] [--full]

Defaults:
  HLQ from MF_HLQ or DRBLEZ
  host/port/user/pass from MF_HOST/MF_PORT/MF_USER/MF_PASS

Uploads:
  SRC  -> HLQ.LUA.SRC  (src/, lua-vm/src/)
  ASM  -> HLQ.LUA.ASM  (src/*.asm)
  INC  -> HLQ.LUA.INC  (include/, lua-vm/src/*.h)
  LUA  -> HLQ.LUA.LUA  (lua/)
  JCL  -> HLQ.LUA.JCL  (jcl/)
  REXX -> HLQ.LUA.REXX (rexx/)
  TEST -> HLQ.LUA.TEST (tests/integration/lua/)

Notes:
  - Uses rewrite-includes during export for SRC/INC to map to PDS member names.
  - Requires pds-map-src.csv, pds-map-asm.csv, and pds-map-inc.csv in repo root.
USAGE
}

HLQ="${MF_HLQ:-DRBLEZ}"
HOST="${MF_HOST:-192.168.1.160}"
PORT="${MF_PORT:-2121}"
USER="${MF_USER:-}"
PASS="${MF_PASS:-}"
DEBUG="no"
DEBUG_FLAG=()
FULL_SYNC="no"
FULL_SYNC_FLAG=()
SYNC_STAMP_DIR="${SYNC_STAMP_DIR:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --hlq) HLQ="$2"; shift 2;;
    --host) HOST="$2"; shift 2;;
    --port) PORT="$2"; shift 2;;
    --user) USER="$2"; shift 2;;
    --pass) PASS="$2"; shift 2;;
    --debug) DEBUG="yes"; shift 1;;
    --full) FULL_SYNC="yes"; shift 1;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
 done

if [[ -z "$USER" || -z "$PASS" ]]; then
  echo "Missing MF_USER/MF_PASS or --user/--pass" >&2
  exit 1
fi

if [[ ! -f pds-map-src.csv || ! -f pds-map-asm.csv || ! -f pds-map-inc.csv ]]; then
  echo "Missing pds-map-src.csv, pds-map-asm.csv, or pds-map-inc.csv. Run scripts/pds_map.py first." >&2
  exit 1
fi

export MF_HOST="$HOST" MF_PORT="$PORT" MF_USER="$USER" MF_PASS="$PASS"

# Change note: support sync stamp directory for Makefile dependency bridging.
# Problem: Make targets could not detect whether MF uploads occurred.
# Expected effect: sync steps touch category stamps only when uploads happen.
# Impact: build/test targets can skip MF submit when nothing changed.
if [[ -n "$SYNC_STAMP_DIR" ]]; then
  mkdir -p "$SYNC_STAMP_DIR"
fi

if [[ "$DEBUG" == "yes" ]]; then
  DEBUG_FLAG=(--debug)
fi
if [[ "$FULL_SYNC" == "yes" ]]; then
  FULL_SYNC_FLAG=(--full)
fi

# Purpose: allow full re-sync across all roots by forwarding --full.
# Fixes: inability to force a complete upload when state marks files as unchanged.
# Expected effect: all files are uploaded even if hashes match.
# Impact: increases FTP traffic for the requested run.
run_step() {
  local name="$1"
  local stamp_name="$2"
  shift
  shift
  local tmp_out=""
  tmp_out="$(mktemp)"
  if [[ "$DEBUG" == "yes" ]]; then
    echo "DEBUG: step $name"
  fi
  set +e
  "$@" | tee "$tmp_out"
  local rc=${PIPESTATUS[0]}
  set -e
  if [[ "$DEBUG" == "yes" ]]; then
    echo "DEBUG: step $name rc=$rc"
  fi
  if [[ -n "$SYNC_STAMP_DIR" && -n "$stamp_name" ]]; then
    if rg -q " -> " "$tmp_out"; then
      touch "$SYNC_STAMP_DIR/$stamp_name"
    fi
  fi
  rm -f "$tmp_out"
  if [[ $rc -ne 0 ]]; then
    echo "ERROR: step $name failed rc=$rc" >&2
    exit $rc
  fi
}

# SRC/INC: VB/1024, LUA/JCL/ASM/REXX: FB/80 (auto defaults in ftp_sync_src.sh)
run_step "SRC-main" "sync_code" scripts/ftp_sync_src.sh --pds "$HLQ.LUA.SRC" --root src --map pds-map-src.csv --use-map --rewrite-includes-map pds-map-inc.csv --ext .c "${DEBUG_FLAG[@]}" "${FULL_SYNC_FLAG[@]}"
run_step "SRC-vm" "sync_code" scripts/ftp_sync_src.sh --pds "$HLQ.LUA.SRC" --root lua-vm/src --map pds-map-src.csv --use-map --rewrite-includes-map pds-map-inc.csv --ext .c "${DEBUG_FLAG[@]}" "${FULL_SYNC_FLAG[@]}"
run_step "ASM" "sync_code" scripts/ftp_sync_src.sh --pds "$HLQ.LUA.ASM" --root src --map pds-map-asm.csv --use-map --ext .asm "${DEBUG_FLAG[@]}" "${FULL_SYNC_FLAG[@]}"
run_step "INC-main" "sync_code" scripts/ftp_sync_src.sh --pds "$HLQ.LUA.INC" --root include --map pds-map-inc.csv --use-map --rewrite-includes-map pds-map-inc.csv --ext .h --ext .inc "${DEBUG_FLAG[@]}" "${FULL_SYNC_FLAG[@]}"
run_step "INC-vm" "sync_code" scripts/ftp_sync_src.sh --pds "$HLQ.LUA.INC" --root lua-vm/src --map pds-map-inc.csv --use-map --rewrite-includes-map pds-map-inc.csv --ext .h --ext .hpp "${DEBUG_FLAG[@]}" "${FULL_SYNC_FLAG[@]}"
run_step "LUA" "sync_lua" scripts/ftp_sync_src.sh --pds "$HLQ.LUA.LUA" --root lua --ext .lua "${DEBUG_FLAG[@]}" "${FULL_SYNC_FLAG[@]}"
run_step "JCL" "sync_jcl" scripts/ftp_sync_src.sh --pds "$HLQ.LUA.JCL" --root jcl --ext .jcl "${DEBUG_FLAG[@]}" "${FULL_SYNC_FLAG[@]}"
run_step "REXX" "sync_rexx" scripts/ftp_sync_src.sh --pds "$HLQ.LUA.REXX" --root rexx --map pds-map-rexx.csv "${DEBUG_FLAG[@]}" "${FULL_SYNC_FLAG[@]}"
run_step "TEST" "sync_test" scripts/ftp_sync_src.sh --pds "$HLQ.LUA.TEST" --root tests --map pds-map-test.csv --ext .lua "${DEBUG_FLAG[@]}" "${FULL_SYNC_FLAG[@]}"
