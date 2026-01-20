#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  sdsf_cmd.sh <mvs command>

Env:
  MF_HOST (default 192.168.1.160)
  MF_PORT (default 2121)
  MF_USER
  MF_PASS

Notes:
  - Runs SDSF batch (ISFAFD) and issues a slash command (e.g. /D PROG,APF).
  - Output is returned from ISFOUT/SYSOUT if allowed by SDSF security.
USAGE
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

HOST="${MF_HOST:-192.168.1.160}"
PORT="${MF_PORT:-2121}"
USER="${MF_USER:-}"
PASS="${MF_PASS:-}"

if [[ -z "$USER" || -z "$PASS" ]]; then
  echo "Missing MF_USER/MF_PASS" >&2
  exit 1
fi

CMD="$*"

TMP_JCL="$(mktemp)"
TMP_LOG="$(mktemp)"
TMP_DIR="$(mktemp)"
trap 'rm -f "$TMP_JCL" "$TMP_LOG" "$TMP_DIR"' EXIT

cat >"$TMP_JCL" <<EOF
//CMDSDSF JOB (ACCT),'SDSF CMD',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID
//S1     EXEC PGM=ISFAFD
//ISFOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSOUT  DD SYSOUT=*
//ISFIN   DD *
/${CMD}
/*
EOF

ftp -inv "$HOST" "$PORT" <<EOF_FTP >"$TMP_LOG"
user $USER $PASS
passive
epsv4
quote SITE FILETYPE=JES
put $TMP_JCL
bye
EOF_FTP

JOBID="$(rg -o "JOB[0-9]+" "$TMP_LOG" | head -n 1)"
if [[ -z "$JOBID" ]]; then
  echo "Failed to detect JOBID. FTP log:" >&2
  cat "$TMP_LOG" >&2
  exit 1
fi

ATTEMPT=1
RETRIES=20
SLEEP=2
while [[ $ATTEMPT -le $RETRIES ]]; do
  if ftp -inv "$HOST" "$PORT" <<EOF_DIR >"$TMP_DIR"
user $USER $PASS
passive
epsv4
quote SITE FILETYPE=JES
quote SITE JESJOBNAME=*
quote SITE JESOWNER=*
quote SITE JESSTATUS=ALL
dir $JOBID
bye
EOF_DIR
  then
    if rg -q "^ *[0-9][0-9][0-9] " "$TMP_DIR"; then
      break
    fi
  fi
  sleep "$SLEEP"
  ATTEMPT=$((ATTEMPT+1))
done

if ! rg -q "^ *[0-9][0-9][0-9] " "$TMP_DIR"; then
  echo "Timed out waiting for $JOBID" >&2
  cat "$TMP_DIR" >&2
  exit 1
fi

ISFOUT_ID="$(awk -v job="$JOBID" '
  /^ *[0-9][0-9][0-9] / {
    if (NF < 6) next;
    if ($5 == "ISFOUT") {
      print job "." $1;
      exit;
    }
  }' "$TMP_DIR")"

SYSOUT_ID="$(awk -v job="$JOBID" '
  /^ *[0-9][0-9][0-9] / {
    if (NF < 6) next;
    if ($5 == "SYSOUT") {
      print job "." $1;
      exit;
    }
  }' "$TMP_DIR")"

JESYSMSG_ID="$(awk -v job="$JOBID" '
  /^ *[0-9][0-9][0-9] / {
    if (NF < 6) next;
    if ($5 == "JESYSMSG") {
      print job "." $1;
      exit;
    }
  }' "$TMP_DIR")"

OUT_ISFOUT="$(mktemp)"
OUT_SYSOUT="$(mktemp)"
OUT_JESYSMSG="$(mktemp)"
trap 'rm -f "$TMP_JCL" "$TMP_LOG" "$TMP_DIR" "$OUT_ISFOUT" "$OUT_SYSOUT" "$OUT_JESYSMSG"' EXIT

fetch_dd() {
  local id="$1"
  local out="$2"
  if [[ -z "$id" ]]; then
    return 0
  fi
  ftp -inv "$HOST" "$PORT" <<EOF_GET >"$TMP_LOG"
user $USER $PASS
passive
epsv4
quote SITE FILETYPE=JES
quote SITE JESJOBNAME=*
quote SITE JESOWNER=*
quote SITE JESSTATUS=ALL
get $id $out
bye
EOF_GET
}

fetch_dd "$ISFOUT_ID" "$OUT_ISFOUT"
fetch_dd "$SYSOUT_ID" "$OUT_SYSOUT"
fetch_dd "$JESYSMSG_ID" "$OUT_JESYSMSG"

if [[ -s "$OUT_ISFOUT" ]]; then
  echo "----- ISFOUT -----"
  cat "$OUT_ISFOUT"
  echo
fi
if [[ -s "$OUT_SYSOUT" ]]; then
  echo "----- SYSOUT -----"
  cat "$OUT_SYSOUT"
  echo
fi
if [[ -s "$OUT_JESYSMSG" ]]; then
  echo "----- JESYSMSG -----"
  cat "$OUT_JESYSMSG"
  echo
fi

if [[ ! -s "$OUT_ISFOUT" && ! -s "$OUT_SYSOUT" && ! -s "$OUT_JESYSMSG" ]]; then
  echo "No output DDs found for $JOBID" >&2
  cat "$TMP_DIR" >&2
  exit 1
fi
