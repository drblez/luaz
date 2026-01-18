#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ftp_submit.sh -j <job.jcl> [-o <output.txt>] [--host H] [--port P] [--user U] [--pass W] [--retries N] [--sleep S]

Env defaults (can override with flags):
  MF_HOST (default 192.168.1.160)
  MF_PORT (default 2121)
  MF_USER
  MF_PASS

Behavior:
  - Submits JCL via FTP in JES mode.
  - Parses JOBID from FTP response.
  - Always polls and downloads job spool.
  - If -o is not provided, saves to jcl/<JOBNAME>_<JOBID>.out.
  - Also archives a copy under jcl/ even when -o is provided.
USAGE
}

HOST="${MF_HOST:-192.168.1.160}"
PORT="${MF_PORT:-2121}"
USER="${MF_USER:-}"
PASS="${MF_PASS:-}"
JCL=""
OUT=""
RETRIES=20
SLEEP=3

while [[ $# -gt 0 ]]; do
  case "$1" in
    -j|--jcl) JCL="$2"; shift 2;;
    -o|--out) OUT="$2"; shift 2;;
    --host) HOST="$2"; shift 2;;
    --port) PORT="$2"; shift 2;;
    --user) USER="$2"; shift 2;;
    --pass) PASS="$2"; shift 2;;
    --retries) RETRIES="$2"; shift 2;;
    --sleep) SLEEP="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
 done

if [[ -z "$JCL" ]]; then
  echo "Missing -j/--jcl" >&2
  usage
  exit 1
fi
if [[ -z "$USER" || -z "$PASS" ]]; then
  echo "Missing MF_USER/MF_PASS or --user/--pass" >&2
  exit 1
fi
if [[ ! -f "$JCL" ]]; then
  echo "JCL not found: $JCL" >&2
  exit 1
fi

TMP_LOG="$(mktemp)"
trap 'rm -f "$TMP_LOG"' EXIT

# Submit JCL
ftp -inv "$HOST" "$PORT" <<EOF_FTP >"$TMP_LOG"
user $USER $PASS
passive
epsv4
quote SITE FILETYPE=JES
put $JCL
bye
EOF_FTP

JOBID="$(rg -o "JOB[0-9]+" "$TMP_LOG" | head -n 1)"
if [[ -z "$JOBID" ]]; then
  echo "Failed to detect JOBID. FTP log:" >&2
  cat "$TMP_LOG" >&2
  exit 1
fi

echo "Submitted as $JOBID"

JOBNAME="$(rg -m1 -o "^//([A-Z0-9$#@]{1,8})\\b" "$JCL" | sed 's#^//##' || true)"
if [[ -z "$JOBNAME" ]]; then
  JOBNAME="$JOBID"
fi
mkdir -p jcl
ARCHIVE_OUT="jcl/${JOBNAME}_${JOBID}.out"
if [[ -z "$OUT" ]]; then
  OUT="$ARCHIVE_OUT"
fi

# Poll for job completion and download spool
ATTEMPT=1
while [[ $ATTEMPT -le $RETRIES ]]; do
  if ftp -inv "$HOST" "$PORT" <<EOF_GET >"$TMP_LOG"
user $USER $PASS
passive
epsv4
quote SITE FILETYPE=JES
quote SITE JESJOBNAME=*
quote SITE JESOWNER=*
quote SITE JESSTATUS=ALL
get $JOBID $OUT
bye
EOF_GET
  then
    if rg -q "^250 " "$TMP_LOG"; then
      if [[ "$OUT" != "$ARCHIVE_OUT" ]]; then
        cp -f "$OUT" "$ARCHIVE_OUT"
      fi
      echo "Fetched spool to $OUT"
      if [[ "$OUT" != "$ARCHIVE_OUT" ]]; then
        echo "Archived spool to $ARCHIVE_OUT"
      fi
      exit 0
    fi
  fi
  sleep "$SLEEP"
  ATTEMPT=$((ATTEMPT+1))
done

echo "Timed out waiting for $JOBID" >&2
cat "$TMP_LOG" >&2
exit 1
