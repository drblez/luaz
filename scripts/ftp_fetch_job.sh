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
  ftp_fetch_job.sh --job JOBnnnnn [--all] [--dd DDNAME] [--step STEPNAME] [--id JESID]
                   [--outdir DIR] [--include-sysudump]

Env:
  MF_HOST (default 192.168.1.160)
  MF_PORT (default 2121)
  MF_USER
  MF_PASS

Examples:
  ftp_fetch_job.sh --job JOB00601 --all
  ftp_fetch_job.sh --job JOB00601 --step RUN --dd SYSUDUMP --outdir jcl
  ftp_fetch_job.sh --job JOB00601 --id 009

Notes:
  - By default, SYSUDUMP is skipped unless --include-sysudump or --dd SYSUDUMP is used.
  - Output files are named <JOBID>_<STEP>_<DD>.out in --outdir.
USAGE
}

HOST="${MF_HOST:-192.168.1.160}"
PORT="${MF_PORT:-2121}"
USER="${MF_USER:-}"
PASS="${MF_PASS:-}"
JOB=""
OUTDIR="jcl"
FETCH_ALL="no"
INCLUDE_SYSUDUMP="no"
FILTER_DD=""
FILTER_STEP=""
FILTER_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --job) JOB="$2"; shift 2;;
    --outdir) OUTDIR="$2"; shift 2;;
    --all) FETCH_ALL="yes"; shift 1;;
    --include-sysudump) INCLUDE_SYSUDUMP="yes"; shift 1;;
    --dd) FILTER_DD="$2"; shift 2;;
    --step) FILTER_STEP="$2"; shift 2;;
    --id) FILTER_ID="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

if [[ -z "$JOB" ]]; then
  echo "Missing --job" >&2
  usage
  exit 1
fi
if [[ -z "$USER" || -z "$PASS" ]]; then
  echo "Missing MF_USER/MF_PASS" >&2
  exit 1
fi

mkdir -p "$OUTDIR"

TMP_DIRLIST="$(mktemp)"
trap 'rm -f "$TMP_DIRLIST"' EXIT

ftp -inv "$HOST" "$PORT" <<EOF_DIR >"$TMP_DIRLIST"
user $USER $PASS
passive
epsv4
quote SITE FILETYPE=JES
quote SITE JESJOBNAME=*
quote SITE JESOWNER=*
quote SITE JESSTATUS=ALL
dir $JOB
bye
EOF_DIR

if ! rg -q "^ *[0-9][0-9][0-9] " "$TMP_DIRLIST"; then
  echo "No spool entries found for $JOB" >&2
  cat "$TMP_DIRLIST" >&2
  exit 1
fi

fetch_one() {
  local id="$1"
  local step="$2"
  local dd="$3"
  local out="$4"
  ftp -inv "$HOST" "$PORT" <<EOF_GET >/dev/null
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

COUNT=0
while read -r jesid step dd; do
  if [[ -n "$FILTER_ID" && "$jesid" != "$FILTER_ID" ]]; then
    continue
  fi
  if [[ -n "$FILTER_STEP" && "$step" != "$FILTER_STEP" ]]; then
    continue
  fi
  if [[ -n "$FILTER_DD" && "$dd" != "$FILTER_DD" ]]; then
    continue
  fi
  if [[ "$FETCH_ALL" != "yes" && -z "$FILTER_DD" && -z "$FILTER_STEP" && -z "$FILTER_ID" ]]; then
    if [[ "$dd" == "SYSUDUMP" && "$INCLUDE_SYSUDUMP" != "yes" ]]; then
      continue
    fi
  fi
  if [[ "$dd" == "SYSUDUMP" && "$INCLUDE_SYSUDUMP" != "yes" && -z "$FILTER_DD" ]]; then
    continue
  fi
  out="$OUTDIR/${JOB}_${step}_${dd}.out"
  fetch_one "$jesid" "$step" "$dd" "$out"
  COUNT=$((COUNT+1))
done < <(awk -v job="$JOB" '
  /^ *[0-9][0-9][0-9] / {
    if (NF < 6) next;
    id=$1; step=$2; dd=$5;
    gsub(/[^A-Za-z0-9_$#@]/,"",step);
    gsub(/[^A-Za-z0-9_$#@]/,"",dd);
    if (step=="" || step=="N/A") step="NA";
    if (dd=="") dd="DD";
    printf "%s.%s %s %s\n", job, id, step, dd;
  }
' "$TMP_DIRLIST")

echo "Downloaded $COUNT files into $OUTDIR"
