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
  ftp_submit.sh -j <job.jcl> [--host H] [--port P] [--user U] [--pass W]
                [--hlq HLQ] [--rebuild LIST] [--rebuild-file FILE]
                [--retries N] [--sleep S] [--spool-retries N] [--spool-sleep S] [--debug]

Env defaults (can override with flags):
  MF_HOST (default 192.168.1.160)
  MF_PORT (default 2121)
  MF_USER
  MF_PASS
  MF_HLQ  (default DRBLEZ)

Behavior:
  - Submits JCL via FTP in JES mode.
  - Parses JOBID from FTP response.
  - Waits for job status OUTPUT before download.
  - Downloads all per-step outputs except SYSUDUMP.
  - Downloads per-step outputs only (no combined spool file).
  - Deletes job output after download only when SYSUDUMP is absent.
  - Prints JOBID, wait start, newly появившиеся spool entries, completion, and overall RC.
  - Fails if any spool entry (except SYSUDUMP) is not downloaded.
  - Optional rebuild list deletes OBJ/HASH members before submit.
    Prefix each member with C: (SRC.HASHES) or A: (ASM.HASHES).
USAGE
}

HOST="${MF_HOST:-192.168.1.160}"
PORT="${MF_PORT:-2121}"
USER="${MF_USER:-}"
PASS="${MF_PASS:-}"
HLQ="${MF_HLQ:-DRBLEZ}"
JCL=""
RETRIES=100
SLEEP=5
SPOOL_RETRIES=3
SPOOL_SLEEP=2
DEBUG="no"
REBUILD_ITEMS=()
REBUILD_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -j|--jcl) JCL="$2"; shift 2;;
    --host) HOST="$2"; shift 2;;
    --port) PORT="$2"; shift 2;;
    --user) USER="$2"; shift 2;;
    --pass) PASS="$2"; shift 2;;
    --hlq) HLQ="$2"; shift 2;;
    --rebuild) REBUILD_ITEMS+=("$2"); shift 2;;
    --rebuild-file) REBUILD_FILE="$2"; shift 2;;
    --retries) RETRIES="$2"; shift 2;;
    --sleep) SLEEP="$2"; shift 2;;
    --spool-retries) SPOOL_RETRIES="$2"; shift 2;;
    --spool-sleep) SPOOL_SLEEP="$2"; shift 2;;
    --debug) DEBUG="yes"; shift 1;;
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
TMP_REBUILD_LOG="$(mktemp)"
KEEP_TMP="no"
if [[ "$DEBUG" == "yes" ]]; then
  KEEP_TMP="yes"
fi
trap 'if [[ "$KEEP_TMP" != "yes" ]]; then rm -f "$TMP_LOG" "$TMP_REBUILD_LOG"; fi' EXIT

if [[ ${#REBUILD_ITEMS[@]} -gt 0 || -n "$REBUILD_FILE" ]]; then
  if [[ "$DEBUG" == "yes" ]]; then
    echo "DEBUG: invoking ftp_rebuild_delete.sh"
  fi
  rebuild_args=()
  for item in "${REBUILD_ITEMS[@]}"; do
    rebuild_args+=(--rebuild "$item")
  done
  if [[ -n "$REBUILD_FILE" ]]; then
    rebuild_args+=(--rebuild-file "$REBUILD_FILE")
  fi
  if [[ "$DEBUG" == "yes" ]]; then
    rebuild_args+=(--debug)
  fi
  scripts/ftp_rebuild_delete.sh \
    --host "$HOST" \
    --port "$PORT" \
    --user "$USER" \
    --pass "$PASS" \
    --hlq "$HLQ" \
    "${rebuild_args[@]}"
fi

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
quote SITE JESRECFM=V
quote SITE NOTRAILINGBLANKS
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
        if (NF >= 6 && $4 ~ /^[A-Z]$/) {
          id=$1; step=$2; dd=$5;
        } else if (NF >= 5 && $3 ~ /^[A-Z]$/) {
          id=$1; step=$2; dd=$4;
        } else {
          next;
        }
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
TMP_PLAN="$(mktemp)"
TMP_OUTLIST="$(mktemp)"
trap 'if [[ "$KEEP_TMP" != "yes" ]]; then rm -f "$TMP_LOG" "$TMP_DIRLIST" "$TMP_PLAN" "$TMP_OUTLIST"; fi' EXIT
if [[ "$DEBUG" == "yes" ]]; then
  echo "DEBUG: TMP_LOG=$TMP_LOG"
  echo "DEBUG: TMP_DIRLIST=$TMP_DIRLIST"
  echo "DEBUG: TMP_PLAN=$TMP_PLAN"
  echo "DEBUG: TMP_OUTLIST=$TMP_OUTLIST"
  echo "DEBUG: starting spool download"
fi

if ftp -inv "$HOST" "$PORT" <<EOF_DIR >"$TMP_DIRLIST"
user $USER $PASS
passive
epsv4
quote SITE FILETYPE=JES
quote SITE JESRECFM=V
quote SITE NOTRAILINGBLANKS
quote SITE JESJOBNAME=*
quote SITE JESOWNER=*
quote SITE JESSTATUS=ALL
dir $JOBID
bye
EOF_DIR
then
  HAS_SYSUDUMP="no"
  if awk '/^ *[0-9][0-9][0-9] / { if (NF>=6 && $5=="SYSUDUMP") { found=1; exit } } END { exit (found?0:1) }' "$TMP_DIRLIST"; then
    HAS_SYSUDUMP="yes"
  fi
  if [[ "$DEBUG" == "yes" ]]; then
    echo "DEBUG: has_sysudump=$HAS_SYSUDUMP"
  fi

  delete_job() {
    local id="$1"
    ftp -inv "$HOST" "$PORT" <<EOF_DEL >>"$TMP_LOG" 2>&1 || true
user $USER $PASS
passive
epsv4
quote SITE FILETYPE=JES
quote SITE JESRECFM=V
quote SITE NOTRAILINGBLANKS
quote SITE JESJOBNAME=*
quote SITE JESOWNER=*
delete $id
bye
EOF_DEL
  }

  fetch_spool() {
    local id="$1"
    local out="$2"
    local attempt=1
    local ok="no"
    local tmp_get
    while [[ $attempt -le $SPOOL_RETRIES ]]; do
      tmp_get="$(mktemp)"
      echo "DEBUG: FETCH $id -> $out (attempt $attempt)" >>"$TMP_LOG"
      echo "SPOOL-DOWNLOAD: id=$id out=$out attempt=$attempt"
      ftp -inv "$HOST" "$PORT" <<EOF_GET >"$tmp_get" 2>&1 || true
user $USER $PASS
passive
epsv4
quote SITE FILETYPE=JES
quote SITE JESRECFM=V
quote SITE NOTRAILINGBLANKS
quote SITE JESJOBNAME=*
quote SITE JESOWNER=*
get $id $out
bye
EOF_GET
      cat "$tmp_get" >>"$TMP_LOG" || true
      if [[ "$DEBUG" != "yes" ]]; then
        rm -f "$tmp_get"
      fi
      if [[ -f "$out" ]]; then
        ok="yes"
        break
      fi
      sleep "$SPOOL_SLEEP"
      attempt=$((attempt+1))
    done
    if [[ "$ok" != "yes" ]]; then
      return 1
    fi
    return 0
  }

  if ! python3 scripts/jes_spool_plan.py \
    --jobid "$JOBID" \
    --jobname "$JOBNAME" \
    --dirlist "$TMP_DIRLIST" \
    --outdir jcl \
    --plan "$TMP_PLAN" \
    --outputs "$TMP_OUTLIST"; then
    echo "Failed to build spool plan for $JOBID" >&2
    if [[ "$DEBUG" == "yes" ]]; then
      echo "DEBUG: TMP_DIRLIST=$TMP_DIRLIST" >&2
      echo "DEBUG: TMP_PLAN=$TMP_PLAN" >&2
      echo "DEBUG: TMP_OUTLIST=$TMP_OUTLIST" >&2
    fi
    exit 1
  fi

  COUNT=0
  JESYSMSG_FILE=""
  declare -a EXPECTED_IDS=()
  declare -A EXPECTED_OUT=()
  declare -A DOWNLOADED=()
  while IFS='|' read -r jesid out step dd; do
      if [[ -z "${jesid:-}" || -z "${out:-}" ]]; then
        continue
      fi
      EXPECTED_IDS+=("$jesid")
      EXPECTED_OUT["$jesid"]="$out"
      if [[ "$DEBUG" == "yes" ]]; then
        echo "DEBUG: fetch $jesid -> $out"
      fi
      if fetch_spool "$jesid" "$out"; then
        COUNT=$((COUNT+1))
        DOWNLOADED["$jesid"]=1
        if [[ "$dd" == "JESYSMSG" ]]; then
          JESYSMSG_FILE="$out"
        fi
      else
        :
      fi
    done <"$TMP_PLAN"
  MISSING=()
  for id in "${EXPECTED_IDS[@]}"; do
    if [[ -z "${DOWNLOADED[$id]+x}" ]]; then
      MISSING+=("$id")
    fi
  done
  if [[ "$DEBUG" == "yes" ]]; then
    echo "DEBUG: downloaded=$COUNT missing=${#MISSING[@]}"
  fi
  if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "Missing spool downloads for $JOBID:" >&2
    for id in "${MISSING[@]}"; do
      echo "  ${id} -> ${EXPECTED_OUT[$id]}" >&2
    done
    if [[ "$DEBUG" == "yes" ]]; then
      echo "DEBUG: TMP_LOG=$TMP_LOG" >&2
      echo "DEBUG: TMP_DIRLIST=$TMP_DIRLIST" >&2
    fi
    exit 1
  fi
  if [[ "$HAS_SYSUDUMP" != "yes" ]]; then
    delete_job "$JOBID" || true
  else
    if [[ "$DEBUG" == "yes" ]]; then
      echo "DEBUG: skip delete for $JOBID (SYSUDUMP present)"
    fi
  fi
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
  # Change note: accept RC=4 only when it originates from HCMP steps.
  # Problem: HASHCMP uses RC=4 for rebuilds; job RC=4 was treated as failure.
  # Expected effect: rebuild-only runs succeed while non-HCMP RC=4 still fail.
  # Impact: return code normalization is based on JESYSMSG content.
  if [[ "$job_rc" == "4" && -n "$JESYSMSG_FILE" && -f "$JESYSMSG_FILE" ]]; then
    if awk '
      /COND CODE/ {
        cc=-1;
        for (i=1; i<=NF; i++) {
          if ($i=="CODE" && (i+1)<=NF) { cc=$(i+1)+0; break; }
        }
        step=$3;
        if (cc>=4) {
          if (step=="HCMP") hcmp=1;
          else bad=1;
        }
      }
      END { exit (hcmp && !bad) ? 0 : 1; }
    ' "$JESYSMSG_FILE"; then
      if [[ "$DEBUG" == "yes" ]]; then
        echo "DEBUG: RC=4 from HCMP only; treating as RC=0"
      fi
      job_rc="0"
    fi
  fi
  if [[ "$job_rc" == "ABEND" || "$job_rc" == "UNKNOWN" ]]; then
    exit 1
  fi
  if [[ "$job_rc" =~ ^[0-9]+$ ]]; then
    if [[ "$job_rc" -gt 255 ]]; then
      exit 255
    fi
    exit "$job_rc"
  fi
  exit 1
fi

exit 0
