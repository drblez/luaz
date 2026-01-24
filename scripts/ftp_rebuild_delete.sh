#!/usr/bin/env bash
set -euo pipefail

# Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
#
# Purpose:
#   Delete OBJ/HASH members via FTP to force rebuild before BUILDINC.
#
# Objects:
# - rebuild_delete: delete requested members from OBJ and HASH PDSEs.

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
  ftp_rebuild_delete.sh [--host H] [--port P] [--user U] [--pass W]
                        [--hlq HLQ] [--rebuild LIST] [--rebuild-file FILE]
                        [--debug]

Notes:
  - Prefix each member with C: (SRC.HASHES) or A: (ASM.HASHES).
  - Unprefixed members delete OBJ and both hash members.
  - See: scripts/ftp_rebuild_delete.md#ftp-delete
USAGE
}

HOST="${MF_HOST:-192.168.1.160}"
PORT="${MF_PORT:-2121}"
USER="${MF_USER:-}"
PASS="${MF_PASS:-}"
HLQ="${MF_HLQ:-DRBLEZ}"
DEBUG="no"
REBUILD_ITEMS=()
REBUILD_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2;;
    --port) PORT="$2"; shift 2;;
    --user) USER="$2"; shift 2;;
    --pass) PASS="$2"; shift 2;;
    --hlq) HLQ="$2"; shift 2;;
    --rebuild) REBUILD_ITEMS+=("$2"); shift 2;;
    --rebuild-file) REBUILD_FILE="$2"; shift 2;;
    --debug) DEBUG="yes"; shift 1;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

if [[ -z "$USER" || -z "$PASS" ]]; then
  echo "Missing MF_USER/MF_PASS or --user/--pass" >&2
  exit 1
fi

TMP_LOG="$(mktemp)"
KEEP_TMP="no"
if [[ "$DEBUG" == "yes" ]]; then
  KEEP_TMP="yes"
fi
trap 'if [[ "$KEEP_TMP" != "yes" ]]; then rm -f "$TMP_LOG"; fi' EXIT

REBUILD_LIST=()

add_rebuild_item() {
  local raw="$1"
  local type="ALL"
  local name=""
  local upper
  upper="${raw^^}"
  if [[ "$upper" =~ ^([CA]):(.+)$ ]]; then
    type="${BASH_REMATCH[1]}"
    name="${BASH_REMATCH[2]}"
  else
    name="$upper"
  fi
  name="${name//[$'\t\r\n ']/}"
  if [[ -z "$name" ]]; then
    return 0
  fi
  if [[ ! "$name" =~ ^[A-Z0-9$#@]{1,8}$ ]]; then
    echo "Invalid rebuild member name: $raw" >&2
    exit 1
  fi
  printf "%s:%s" "$type" "$name"
}

normalize_rebuild_items() {
  local item
  local token
  local normalized
  for item in "$@"; do
    for token in ${item//,/ }; do
      token="${token//[$'\t\r\n ']/}"
      if [[ -n "$token" ]]; then
        normalized="$(add_rebuild_item "$token")"
        if [[ -n "$normalized" ]]; then
          REBUILD_LIST+=("$normalized")
        fi
      fi
    done
  done
}

load_rebuild_file() {
  local line
  if [[ -z "$REBUILD_FILE" ]]; then
    return 0
  fi
  if [[ ! -f "$REBUILD_FILE" ]]; then
    echo "Rebuild file not found: $REBUILD_FILE" >&2
    exit 1
  fi
  while IFS= read -r line; do
    line="${line%%#*}"
    line="${line%%;*}"
    line="${line//$'\r'/}"
    if [[ -n "${line//[$'\t ']/}" ]]; then
      normalize_rebuild_items "$line"
    fi
  done <"$REBUILD_FILE"
}

normalize_rebuild_items "${REBUILD_ITEMS[@]}"
load_rebuild_file

if [[ ${#REBUILD_LIST[@]} -eq 0 ]]; then
  if [[ "$DEBUG" == "yes" ]]; then
    echo "DEBUG: no rebuild members provided"
  fi
  exit 0
fi

if [[ "$DEBUG" == "yes" ]]; then
  echo "DEBUG: rebuild members: ${REBUILD_LIST[*]}"
fi

tmp_cmds="$(mktemp)"
trap 'if [[ "$KEEP_TMP" != "yes" ]]; then rm -f "$TMP_LOG" "$tmp_cmds"; fi' EXIT

: >"$tmp_cmds"
printf "user %s %s\n" "$USER" "$PASS" >>"$tmp_cmds"
printf "%s\n" "passive" >>"$tmp_cmds"
printf "%s\n" "epsv4" >>"$tmp_cmds"
printf "%s\n" "quote SITE FILETYPE=SEQ" >>"$tmp_cmds"
for item in "${REBUILD_LIST[@]}"; do
  IFS=':' read -r type member <<<"$item"
  printf "delete '%s.LUA.OBJ(%s)'\n" "$HLQ" "$member" >>"$tmp_cmds"
  if [[ "$type" == "C" ]]; then
    printf "delete '%s.LUA.SRC.HASHES(%s)'\n" "$HLQ" "$member" >>"$tmp_cmds"
  elif [[ "$type" == "A" ]]; then
    printf "delete '%s.LUA.ASM.HASHES(%s)'\n" "$HLQ" "$member" >>"$tmp_cmds"
  else
    printf "delete '%s.LUA.SRC.HASHES(%s)'\n" "$HLQ" "$member" >>"$tmp_cmds"
    printf "delete '%s.LUA.ASM.HASHES(%s)'\n" "$HLQ" "$member" >>"$tmp_cmds"
  fi
done
printf "%s\n" "bye" >>"$tmp_cmds"

ftp -inv "$HOST" "$PORT" <"$tmp_cmds" >"$TMP_LOG" 2>&1 || true

if [[ "$DEBUG" == "yes" ]]; then
  echo "DEBUG: rebuild delete commands:"
  sed -e 's/^user .*/user <redacted>/' "$tmp_cmds"
  echo "DEBUG: rebuild delete log:"
  cat "$TMP_LOG"
fi

if rg -q "^550 .*does not exist\\.|^550 .*does not exist$" "$TMP_LOG"; then
  if [[ "$DEBUG" == "yes" ]]; then
    echo "DEBUG: ignore missing members (550 does not exist)"
  fi
fi

if rg -q "^(553|425) " "$TMP_LOG"; then
  echo "Rebuild delete failed (FTP error)." >&2
  exit 1
fi

if rg -q "^550 " "$TMP_LOG" && ! rg -q "does not exist" "$TMP_LOG"; then
  echo "Rebuild delete failed (FTP 550)." >&2
  exit 1
fi

exit 0
