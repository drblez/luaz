#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ftp_submit.sh -j <job.jcl> [--host H] [--port P] [--user U] [--pass W] [--retries N] [--sleep S]

Env defaults (can override with flags):
  MF_HOST (default 192.168.1.160)
  MF_PORT (default 2121)
  MF_USER
  MF_PASS

Behavior:
  - Submits JCL via FTP in JES mode.
  - Parses JOBID from FTP response.
  - Downloads per-step outputs as jcl/<JOBNAME>_<JOBID>_<STEP>_<DD>.out.
  - Builds combined jcl/<JOBNAME>_<JOBID>.out from per-step outputs (excluding SYSUDUMP).
  - Downloads SYSUDUMP separately (if present) after per-step outputs.
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
if [[ -n "$OUT" ]]; then
  echo "Warning: -o/--out is ignored; combined spool name is fixed." >&2
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

# Poll for job completion
ATTEMPT=1
SUCCESS="no"
while [[ $ATTEMPT -le $RETRIES ]]; do
  if ftp -inv "$HOST" "$PORT" <<EOF_DIR >"$TMP_LOG"
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
    if rg -q "^ *[0-9][0-9][0-9] " "$TMP_LOG"; then
      echo "Job $JOBID is ready"
      SUCCESS="yes"
      break
    fi
  fi
  sleep "$SLEEP"
  ATTEMPT=$((ATTEMPT+1))
done

if [[ "$SUCCESS" != "yes" ]]; then
  echo "Timed out waiting for $JOBID" >&2
  cat "$TMP_LOG" >&2
  exit 1
fi

# Download per-step outputs for quick navigation (excluding SYSUDUMP)
TMP_DIRLIST="$(mktemp)"
trap 'rm -f "$TMP_LOG" "$TMP_DIRLIST"' EXIT

if ftp -inv "$HOST" "$PORT" <<EOF_DIR >"$TMP_DIRLIST"
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
  COUNT=0
  : > "$ARCHIVE_OUT"
  SYSUDUMP_IDS=()
  while read -r jesid step dd; do
      if [[ "$dd" == "SYSUDUMP" ]]; then
        SYSUDUMP_IDS+=("$jesid" "$step")
        continue
      fi
      out="jcl/${JOBNAME}_${JOBID}_${step}_${dd}.out"
      if ftp -inv "$HOST" "$PORT" <<EOF_GET >>"$TMP_LOG"
user $USER $PASS
passive
epsv4
quote SITE FILETYPE=JES
quote SITE JESJOBNAME=*
quote SITE JESOWNER=*
get $jesid $out
bye
EOF_GET
      then
        if [[ -f "$out" ]]; then
          {
            echo "----- ${JOBNAME} ${JOBID} ${step} ${dd} -----"
            cat "$out"
            echo
          } >> "$ARCHIVE_OUT"
          COUNT=$((COUNT+1))
        else
          echo "Warning: missing per-step output $out" >&2
        fi
      fi
    done < <(awk -v job="$JOBID" '
      /^ *[0-9][0-9][0-9] / {
        if (NF < 6) next;
        if ($4 !~ /^[A-Z]$/) next;
        id=$1; step=$2; dd=$5;
        gsub(/[^A-Za-z0-9_$#@]/,"",step);
        gsub(/[^A-Za-z0-9_$#@]/,"",dd);
        if (step=="" || step=="N/A") step="NA";
        if (dd=="") dd="DD";
      printf "%s.%s %s %s\n", job, id, step, dd;
      }
    ' "$TMP_DIRLIST")
  echo "Downloaded $COUNT per-step outputs"
  echo "Built combined spool (without SYSUDUMP) at $ARCHIVE_OUT"
  if [[ ${#SYSUDUMP_IDS[@]} -gt 0 ]]; then
    i=0
    while [[ $i -lt ${#SYSUDUMP_IDS[@]} ]]; do
      jesid="${SYSUDUMP_IDS[$i]}"
      step="${SYSUDUMP_IDS[$((i+1))]}"
      out="jcl/${JOBNAME}_${JOBID}_${step}_SYSUDUMP.out"
      if ftp -inv "$HOST" "$PORT" <<EOF_DUMP >>"$TMP_LOG"
user $USER $PASS
passive
epsv4
quote SITE FILETYPE=JES
quote SITE JESJOBNAME=*
quote SITE JESOWNER=*
get $jesid $out
bye
EOF_DUMP
      then
        if [[ -f "$out" ]]; then
          echo "Fetched SYSUDUMP to $out"
        else
          echo "Warning: missing SYSUDUMP output $out" >&2
        fi
      fi
      i=$((i+2))
    done
  fi
fi

exit 0
