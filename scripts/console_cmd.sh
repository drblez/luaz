#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  console_cmd.sh <mvs command>

Env:
  MF_HOST (default 192.168.1.160)
  MF_PORT (default 2121)
  MF_USER
  MF_PASS

Notes:
  - Uses SDSF batch (ISFAFD) and issues a slash command.
  - Switches to LOG and refreshes before reading output.
  - Filters SDSF menu to show only RESPONSE lines.
  - Uses a pager (less) when available.
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
  LOG
/${CMD}
  AFD REFRESH
  END
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
RETRIES=60
SLEEP=3
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
    if rg -q "^CMDSDSF +$JOBID +.*OUTPUT" "$TMP_DIR"; then
      break
    fi
  fi
  sleep "$SLEEP"
  ATTEMPT=$((ATTEMPT+1))
done

if ! rg -q "^CMDSDSF +$JOBID +.*OUTPUT" "$TMP_DIR"; then
  echo "Timed out waiting for $JOBID" >&2
  cat "$TMP_DIR" >&2
  exit 1
fi

JOBNAME="CMDSDSF"
mkdir -p jcl

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

OUT_ISFOUT="jcl/${JOBNAME}_${JOBID}_S1_ISFOUT.out"
OUT_SYSOUT="jcl/${JOBNAME}_${JOBID}_S1_SYSOUT.out"
OUT_JESYSMSG="jcl/${JOBNAME}_${JOBID}_JES2_JESYSMSG.out"
trap 'rm -f "$TMP_JCL" "$TMP_LOG" "$TMP_DIR"' EXIT

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
  CLEAN_ISFOUT="$(mktemp)"
  trap 'rm -f "$TMP_JCL" "$TMP_LOG" "$TMP_DIR" "$CLEAN_ISFOUT"' EXIT
  LC_ALL=C awk '{ gsub(/[^[:print:]\t]/,""); print }' "$OUT_ISFOUT" > "$CLEAN_ISFOUT"
  RESPONSE_BLOCK="$(mktemp)"
  trap 'rm -f "$TMP_JCL" "$TMP_LOG" "$TMP_DIR" "$CLEAN_ISFOUT" "$RESPONSE_BLOCK"' EXIT
  LC_ALL=C awk '
    /RESPONSE=/ {show=1}
    show && /SDSF MENU/ {exit}
    show && /COMMAND INPUT/ {exit}
    show {print}
  ' "$CLEAN_ISFOUT" > "$RESPONSE_BLOCK"
  if [[ -s "$RESPONSE_BLOCK" ]]; then
    if rg -q "RESPONSES NOT SHOWN" "$RESPONSE_BLOCK"; then
      echo "WARNING: SDSF truncated output. Re-run to page further."
      echo
    fi
    if [[ -t 1 ]] && command -v less >/dev/null 2>&1; then
      less -R "$RESPONSE_BLOCK"
    else
      cat "$RESPONSE_BLOCK"
    fi
  else
    echo "No RESPONSE block found. Check SDSF access or command syntax." >&2
  fi
  echo
fi
if [[ -s "$OUT_SYSOUT" ]]; then
  echo "----- SYSOUT -----"
  cat "$OUT_SYSOUT"
  echo
fi

if [[ ! -s "$OUT_ISFOUT" && ! -s "$OUT_SYSOUT" && ! -s "$OUT_JESYSMSG" ]]; then
  echo "No output DDs found for $JOBID" >&2
  cat "$TMP_DIR" >&2
  exit 1
fi

echo "Saved outputs:"
[[ -s "$OUT_ISFOUT" ]] && echo "  $OUT_ISFOUT"
[[ -s "$OUT_SYSOUT" ]] && echo "  $OUT_SYSOUT"
