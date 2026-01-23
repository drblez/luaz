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
  ftp_submit.sh -j <job.jcl> [--host H] [--port P] [--user U] [--pass W] [--retries N] [--sleep S]

Env defaults (can override with flags):
  MF_HOST (default 192.168.1.160)
  MF_PORT (default 2121)
  MF_USER
  MF_PASS

Behavior:
  - Submits JCL via FTP in JES mode.
  - Parses JOBID from FTP response.
  - Waits for job status OUTPUT before download.
  - Downloads all per-step outputs except SYSUDUMP.
  - Downloads per-step outputs only (no combined spool file).
  - Deletes each spool entry after it is downloaded.
  - Prints JOBID, wait start, newly появившиеся spool entries, completion, and overall RC.
USAGE
}

HOST="${MF_HOST:-192.168.1.160}"
PORT="${MF_PORT:-2121}"
USER="${MF_USER:-}"
PASS="${MF_PASS:-}"
JCL=""
RETRIES=100
SLEEP=5

while [[ $# -gt 0 ]]; do
  case "$1" in
    -j|--jcl) JCL="$2"; shift 2;;
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

JOBNAME="$(rg -m1 -o "^//([A-Z0-9$#@]{1,8})\\b" "$JCL" | sed 's#^//##' || true)"
if [[ -z "$JOBNAME" ]]; then
  JOBNAME="$JOBID"
fi

echo "JOBID=$JOBID"
echo "WAIT: polling for OUTPUT"

mkdir -p jcl

# Poll for job completion (OUTPUT)
declare -A SEEN_SPOOL=()
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
    STATUS="$(awk '
      /^JOBNAME[[:space:]]+JOBID[[:space:]]+OWNER[[:space:]]+STATUS/ {hdr=1; next}
      hdr && NF>=4 {print $4; exit}
    ' "$TMP_LOG")"
    while read -r id step dd; do
      key="${id}|${step}|${dd}"
      if [[ -z "${SEEN_SPOOL[$key]+x}" ]]; then
        SEEN_SPOOL["$key"]=1
        echo "SPOOL+ ${id} ${step} ${dd}"
      fi
    done < <(awk '
      /^ *[0-9][0-9][0-9] / {
        if (NF < 6) next;
        if ($4 !~ /^[A-Z]$/) next;
        id=$1; step=$2; dd=$5;
        gsub(/[^A-Za-z0-9_$#@]/,"",step);
        gsub(/[^A-Za-z0-9_$#@]/,"",dd);
        if (step=="" || step=="N/A") step="NA";
        if (dd=="") dd="DD";
        printf "%s %s %s\n", id, step, dd;
      }
    ' "$TMP_LOG")
    if [[ "$STATUS" == "OUTPUT" ]]; then
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

echo "DONE: job is OUTPUT"

# Download per-step outputs (excluding SYSUDUMP)
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
  delete_spool() {
    local id="$1"
    ftp -inv "$HOST" "$PORT" <<EOF_DEL >>"$TMP_LOG"
user $USER $PASS
passive
epsv4
quote SITE FILETYPE=JES
quote SITE JESJOBNAME=*
quote SITE JESOWNER=*
delete $id
bye
EOF_DEL
  }

  COUNT=0
  JESYSMSG_FILE=""
  while read -r jesid step dd; do
      if [[ "$dd" == "SYSUDUMP" ]]; then
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
          COUNT=$((COUNT+1))
          delete_spool "$jesid" || true
        fi
        if [[ "$dd" == "JESYSMSG" ]]; then
          JESYSMSG_FILE="$out"
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
  job_rc=""
  if [[ -n "$JESYSMSG_FILE" && -f "$JESYSMSG_FILE" ]]; then
    job_rc="$(rg -m1 "ENDED - RC=" "$JESYSMSG_FILE" 2>/dev/null | sed -n 's/.*RC= *\\([0-9][0-9]*\\).*/\\1/p' || true)"
  fi
  if [[ -z "$job_rc" ]]; then
    job_rc="$(rg -m1 "ENDED - RC=" "jcl/${JOBNAME}_${JOBID}_*.out" 2>/dev/null | sed -n 's/.*RC= *\\([0-9][0-9]*\\).*/\\1/p' || true)"
  fi
  if [[ -z "$job_rc" ]]; then
    job_rc="$(rg -m1 "RC= *[0-9]{1,4}" "jcl/${JOBNAME}_${JOBID}_*.out" 2>/dev/null | sed -n 's/.*RC= *\\([0-9][0-9]*\\).*/\\1/p' || true)"
  fi
  if [[ -z "$job_rc" && -n "$JESYSMSG_FILE" && -f "$JESYSMSG_FILE" ]]; then
    if rg -q "ABEND" "$JESYSMSG_FILE"; then
      job_rc="ABEND"
    else
      job_rc="$(awk '
        /COND CODE/ {
          for (i=1; i<=NF; i++) {
            if ($i=="CODE" && (i+1)<=NF && $(i+1) ~ /^[0-9]+$/) {
              v=$(i+1)+0;
              seen=1;
              if (v>max) max=v;
            }
          }
        }
        END {
          if (max>0 || seen) {
            printf "%d", max;
          }
        }
      ' "$JESYSMSG_FILE")"
    fi
  fi
  if [[ -z "$job_rc" ]]; then
    job_rc="UNKNOWN"
  fi
  echo "RC=$job_rc"
fi

exit 0
