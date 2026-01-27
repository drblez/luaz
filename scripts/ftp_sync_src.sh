#!/usr/bin/env bash
# Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
#
# Sync local sources to a z/OS PDS via FTP.
#
# Object Table:
# | Object | Kind | Purpose |
# |--------|------|---------|
# | ftp_sync_src.sh | script | Upload files from a directory to a PDS |
# | usage | function | Print CLI help |
# | cleanup | function | Remove temp files/dirs |
#
# Notes:
# - Supports staging (copy + include rewrites) before upload.
#
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
  ftp_sync_src.sh --pds HLQ.PDS --root <dir> [--host H] [--port P] [--user U] [--pass W] [--map FILE]
                 [--rewrite-includes-map FILE] [--recfm R] [--lrecl N] [--blksize N] [--state FILE]
                 [--full]
                 [--use-map] [--ext .jcl]... [--file PATH] [--debug]

Defaults:
  --root .
  --host from MF_HOST or 192.168.1.160
  --port from MF_PORT or 2121
  --user from MF_USER
  --pass from MF_PASS
  --map  (auto: pds-map-*.csv based on --root when present; else ./pds-map.txt)
  --rewrite-includes-map  (auto: pds-map-inc.csv when present)
  --recfm/--lrecl  (auto by file type if not provided)
     - .c/.h/.inc => VB/1024
     - .asm/.jcl/.lua/.rexx => FB/80
     - default => FB/80
  --state (default: MF_SYNC_STATE or $XDG_CACHE_HOME/luaz/ftp_sync_state.json)
  --full (force full upload, ignore sync state)
  --blksize (default 0)
  --use-map  (auto: use existing CSV map when present; otherwise generate)
  --ext  (repeatable; limit files by extension, e.g. --ext .jcl)
  --file (sync a single file; path may be absolute or relative to --root)
  --debug (print detailed FTP log output)

Notes:
  - Uses FILETYPE=SEQ with RECFM/LRECL/BLKSIZE as provided.
  - Member names are derived from basename, uppercased, non-alnum => '_', truncated to 8.
  - Collisions are resolved with a 2-hex suffix (first 6 + suffix).
  - Include rewrites are enabled by default when C/INC/H files are present and pds-map-inc.csv exists.
USAGE
}

HOST="${MF_HOST:-192.168.1.160}"
PORT="${MF_PORT:-2121}"
USER="${MF_USER:-}"
PASS="${MF_PASS:-}"
ROOT="."
PDS=""
MAP=""
MAP_SET="no"
REWRITE_MAP=""
REWRITE_SET="no"
RECFM=""
LRECL=""
BLKSIZE=""
RECFM_SET="no"
LRECL_SET="no"
BLKSIZE_SET="no"
USE_MAP=""
USE_MAP_SET="no"
DEBUG="no"
EXTS=()
FILE_ONLY=""
FILE_ONLY_REL=""
FILE_ONLY_EXT=""
AUTO_REWRITE="no"
AUTO_ASMFMT="no"
STATE_FILE=""
STATE_SET="no"
FULL_SYNC="no"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pds) PDS="$2"; shift 2;;
    --root) ROOT="$2"; shift 2;;
    --host) HOST="$2"; shift 2;;
    --port) PORT="$2"; shift 2;;
    --user) USER="$2"; shift 2;;
    --pass) PASS="$2"; shift 2;;
    --map) MAP="$2"; MAP_SET="yes"; shift 2;;
    --rewrite-includes-map) REWRITE_MAP="$2"; REWRITE_SET="yes"; shift 2;;
    --recfm) RECFM="$2"; RECFM_SET="yes"; shift 2;;
    --lrecl) LRECL="$2"; LRECL_SET="yes"; shift 2;;
    --blksize) BLKSIZE="$2"; BLKSIZE_SET="yes"; shift 2;;
    --state) STATE_FILE="$2"; STATE_SET="yes"; shift 2;;
    --full) FULL_SYNC="yes"; shift 1;;
    --use-map) USE_MAP="yes"; USE_MAP_SET="yes"; shift 1;;
    --ext) EXTS+=("$2"); shift 2;;
    --file) FILE_ONLY="$2"; shift 2;;
    --debug) DEBUG="yes"; shift 1;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1;;
  esac
done

if [[ -z "$PDS" ]]; then
  echo "Missing --pds" >&2
  usage
  exit 1
fi
if [[ -z "$USER" || -z "$PASS" ]]; then
  echo "Missing MF_USER/MF_PASS or --user/--pass" >&2
  exit 1
fi
if [[ ! -d "$ROOT" ]]; then
  echo "Root dir not found: $ROOT" >&2
  exit 1
fi

# Purpose: track staged file hashes to skip unchanged uploads.
# Fixes: unnecessary FTP transfers for files that did not change.
# Expected effect: only changed members are uploaded; unchanged are skipped.
# Impact: sync behavior depends on a local state file unless --full is used.
if [[ "$STATE_SET" != "yes" ]]; then
  STATE_FILE="${MF_SYNC_STATE:-}"
  if [[ -z "$STATE_FILE" ]]; then
    CACHE_ROOT="${XDG_CACHE_HOME:-${HOME:-.}/.cache}"
    STATE_FILE="$CACHE_ROOT/luaz/ftp_sync_state.json"
  fi
fi
STATE_DIR="$(dirname -- "$STATE_FILE")"
mkdir -p "$STATE_DIR"
if [[ -n "$FILE_ONLY" ]]; then
  read -r FILE_ONLY_REL FILE_ONLY_EXT < <(python3 - <<'PY' "$ROOT" "$FILE_ONLY"
import os, sys
root = os.path.abspath(sys.argv[1])
f = sys.argv[2]
if not os.path.isabs(f):
    cand = os.path.abspath(f)
    if os.path.isfile(cand):
        f = cand
    else:
        f = os.path.abspath(os.path.join(root, f))
else:
    f = os.path.abspath(f)
if not os.path.isfile(f):
    sys.stderr.write(f"File not found: {f}\n")
    raise SystemExit(2)
if not (f == root or f.startswith(root + os.sep)):
    sys.stderr.write(f"File not under root: {f}\n")
    raise SystemExit(2)
rel = os.path.relpath(f, root)
ext = os.path.splitext(rel)[1].lower()
print(f"{rel}\t{ext}")
PY
)
  ext="$FILE_ONLY_EXT"
  if [[ -n "$ext" ]]; then
    if [[ ${#EXTS[@]} -eq 0 ]]; then
      EXTS+=("$ext")
    fi
    case "$ext" in
      .c|.h|.inc) AUTO_REWRITE="yes" ;;
      .asm) AUTO_ASMFMT="yes" ;;
    esac
  fi
fi

detect_map_defaults() {
  local root_norm
  local base
  local candidate=""
  root_norm="$(printf '%s' "$ROOT" | sed 's:/*$::')"
  base="$(basename "$root_norm")"
  if [[ "$MAP_SET" != "yes" ]]; then
    if [[ -z "$MAP" && ${#EXTS[@]} -gt 0 ]]; then
      for ext in "${EXTS[@]}"; do
        case "$ext" in
          .asm) MAP="pds-map-asm.csv"; break ;;
          .jcl) MAP="pds-map-jcl.csv"; break ;;
          .inc|.h) MAP="pds-map-inc.csv"; break ;;
          .c) MAP="pds-map-src.csv"; break ;;
          .lua) MAP="pds-map-lua.csv"; break ;;
          .rexx|.rex) MAP="pds-map-rexx.csv"; break ;;
        esac
      done
    fi
    if [[ -z "$MAP" ]]; then
      if [[ "$root_norm" == *"/tests/integration/lua" ]]; then
        candidate="pds-map-test.csv"
      fi
      case "$base" in
        src) candidate="pds-map-src.csv" ;;
        include) candidate="pds-map-inc.csv" ;;
        jcl) candidate="pds-map-jcl.csv" ;;
        lua) candidate="${candidate:-pds-map-lua.csv}" ;;
        rexx) candidate="pds-map-rexx.csv" ;;
        *) candidate="" ;;
      esac
      if [[ -n "$candidate" ]]; then
        MAP="$candidate"
      fi
    fi
  fi
  if [[ -z "$MAP" ]]; then
    MAP="./pds-map.txt"
  fi
  if [[ "$USE_MAP_SET" != "yes" ]]; then
    if [[ -f "$MAP" ]]; then
      USE_MAP="yes"
    else
      USE_MAP="no"
    fi
  fi
}

detect_map_defaults

if [[ -z "$REWRITE_MAP" ]]; then
  for ext in "${EXTS[@]:-}"; do
    if [[ "$ext" == ".c" || "$ext" == ".h" || "$ext" == ".inc" ]]; then
      AUTO_REWRITE="yes"
      break
    fi
  done
  if [[ "$AUTO_REWRITE" != "yes" && ${#EXTS[@]} -eq 0 ]]; then
    if find "$ROOT" -type f \( -name '*.c' -o -name '*.h' -o -name '*.inc' \) -print -quit | rg -q .; then
      AUTO_REWRITE="yes"
    fi
  fi
  if [[ "$AUTO_REWRITE" == "yes" ]]; then
    if [[ -f "pds-map-inc.csv" ]]; then
      REWRITE_MAP="pds-map-inc.csv"
    else
      echo "Rewrite map not found: pds-map-inc.csv" >&2
      exit 1
    fi
  fi
fi

detect_defaults() {
  local has_vb="no"
  local has_fb="no"
  local desired_mode=""
  if [[ -n "$FILE_ONLY_REL" ]]; then
    case "$FILE_ONLY_EXT" in
      .c|.h|.inc) has_vb="yes" ;;
      .asm|.jcl|.lua|.rexx|.rex) has_fb="yes" ;;
    esac
  elif [[ ${#EXTS[@]} -gt 0 ]]; then
    for ext in "${EXTS[@]}"; do
      case "$ext" in
        .c|.h|.inc) has_vb="yes" ;;
        .asm|.jcl|.lua|.rexx|.rex) has_fb="yes" ;;
      esac
    done
  else
    if find "$ROOT" -type f \( -name '*.c' -o -name '*.h' -o -name '*.inc' \) -print -quit | rg -q .; then
      has_vb="yes"
    fi
    if find "$ROOT" -type f \( -name '*.asm' -o -name '*.jcl' -o -name '*.lua' -o -name '*.rexx' -o -name '*.rex' \) -print -quit | rg -q .; then
      has_fb="yes"
    fi
  fi
  if [[ "$has_vb" == "yes" ]]; then
    desired_mode="VB"
  elif [[ "$has_fb" == "yes" ]]; then
    desired_mode="FB"
  else
    desired_mode="FB"
  fi
  if [[ "$RECFM_SET" != "yes" ]]; then
    RECFM="$desired_mode"
  fi
  if [[ "$LRECL_SET" != "yes" ]]; then
    if [[ "$RECFM" == "VB" ]]; then
      LRECL="1024"
    else
      LRECL="80"
    fi
  fi
  if [[ "$BLKSIZE_SET" != "yes" ]]; then
    BLKSIZE="0"
  fi
}

detect_defaults

for ext in "${EXTS[@]:-}"; do
  if [[ "$ext" == ".asm" ]]; then
    AUTO_ASMFMT="yes"
    break
  fi
done
if [[ "$AUTO_ASMFMT" != "yes" && ${#EXTS[@]} -eq 0 ]]; then
  if find "$ROOT" -type f -name '*.asm' -print -quit | rg -q .; then
    AUTO_ASMFMT="yes"
  fi
fi

STAGE_ROOT="$ROOT"
STAGE_DIR=""
TMP_FTP=""
TMP_LIST=""
TMP_LOG=""
TMP_STATE=""

cleanup() {
  [[ -n "$TMP_FTP" && -f "$TMP_FTP" ]] && rm -f "$TMP_FTP"
  [[ -n "$TMP_LIST" && -f "$TMP_LIST" ]] && rm -f "$TMP_LIST"
  [[ -n "$TMP_LOG" && -f "$TMP_LOG" ]] && rm -f "$TMP_LOG"
  [[ -n "$TMP_STATE" && -f "$TMP_STATE" ]] && rm -f "$TMP_STATE"
  [[ -n "$STAGE_DIR" && -d "$STAGE_DIR" ]] && rm -rf "$STAGE_DIR"
  return 0
}
trap cleanup EXIT

if [[ -n "$REWRITE_MAP" || "$AUTO_ASMFMT" == "yes" ]]; then
  if [[ ! -f "$REWRITE_MAP" ]]; then
    if [[ -n "$REWRITE_MAP" ]]; then
      echo "Rewrite map not found: $REWRITE_MAP" >&2
      exit 1
    fi
  fi
  STAGE_DIR="$(mktemp -d)"
  cp -R "$ROOT"/. "$STAGE_DIR"/
  if [[ -n "$REWRITE_MAP" ]]; then
    scripts/rewrite_includes.py --map "$REWRITE_MAP" --root "$STAGE_DIR" >/dev/null
  fi
  STAGE_ROOT="$STAGE_DIR"
fi

TMP_FTP="$(mktemp)"
TMP_LIST="$(mktemp)"
TMP_LOG="$(mktemp)"
TMP_STATE="$(mktemp)"

FTP_SYNC_FILE_ONLY="$FILE_ONLY_REL" python3 - <<'PY' "$ROOT" "$STAGE_ROOT" "$PDS" "$MAP" "$TMP_FTP" "$TMP_LIST" "$RECFM" "$LRECL" "$BLKSIZE" "$USE_MAP" "$STATE_FILE" "$TMP_STATE" "$FULL_SYNC" "${EXTS[@]:-}"
import os, re, sys, binascii, hashlib, json
orig_root, stage_root, pds, map_path, ftp_path, list_path, recfm, lrecl, blksize, use_map, state_path, state_out, full_sync, *exts = sys.argv[1:]
full_sync = (full_sync == "yes")
# Purpose: exclude Markdown from sync to MF by default.
# Problem: .md files are documentation and must not be uploaded to PDS.
# Expected effect: skip .md in scans and refuse explicit .md sync.
# Impact: .md sources never reach MF datasets via this script.
ignore_exts = {".md"}

files = []
orig_root = os.path.normpath(orig_root)
stage_root = os.path.normpath(stage_root)
exts = [e.lower() for e in exts if e]
file_only = os.environ.get("FTP_SYNC_FILE_ONLY", "")
if file_only:
    file_only = os.path.normpath(file_only)
    if os.path.splitext(file_only)[1].lower() in ignore_exts:
        raise SystemExit(f"Refusing to sync ignored extension: {file_only}")

map_entries = []
map_paths = set()
mem_used = set()
if use_map == "yes" and os.path.exists(map_path):
    import csv
    with open(map_path, newline='', encoding='utf-8') as f:
        rd = csv.DictReader(f)
        for row in rd:
            rel = row['relative_path']
            mem = row['member']
            mem_used.add(mem)
            rel_norm = os.path.normpath(rel)
            if orig_root in (".", ""):
                rel_tail = rel_norm
            else:
                if rel_norm.startswith(orig_root + os.sep):
                    rel_tail = rel_norm[len(orig_root) + 1:]
                else:
                    rel_tail = rel_norm
            ext = os.path.splitext(rel_tail)[1].lower()
            if ext in ignore_exts:
                continue
            if exts and ext not in exts:
                continue
            if file_only and rel_tail != file_only:
                continue
            map_paths.add(rel_tail)
            if not os.path.exists(os.path.join(stage_root, rel_tail)):
                continue
            map_entries.append((rel_tail, mem))
else:
    if file_only:
        p = os.path.join(stage_root, file_only)
        if not os.path.isfile(p):
            raise SystemExit(f"missing file: {p}")
        files = [p]
    else:
        for base, _, names in os.walk(stage_root):
            for n in names:
                p = os.path.join(base, n)
                if os.path.isfile(p):
                    ext = os.path.splitext(p)[1].lower()
                    if ext in ignore_exts:
                        continue
                    if exts and ext not in exts:
                        continue
                    files.append(p)
        files.sort()

if use_map == "yes":
    all_files = []
    if file_only:
        all_files = [file_only]
    else:
        for base, _, names in os.walk(stage_root):
            for n in names:
                p = os.path.join(base, n)
                if os.path.isfile(p):
                    ext = os.path.splitext(p)[1].lower()
                    if ext in ignore_exts:
                        continue
                    if exts and ext not in exts:
                        continue
                    rel = os.path.relpath(p, stage_root)
                    all_files.append(rel)
        all_files.sort()
    def auto_ok(rel):
        stem = os.path.splitext(os.path.basename(rel))[0]
        return 1 <= len(stem) <= 8 and re.fullmatch(r'[A-Za-z0-9$#@]+', stem) is not None
    def auto_member(rel):
        stem = os.path.splitext(os.path.basename(rel))[0]
        return stem.upper()
    missing = []
    for rel in all_files:
        if rel in map_paths:
            continue
        if auto_ok(rel):
            mem = auto_member(rel)
            if mem in mem_used:
                sys.stderr.write(f"Auto-mapped member conflict in {map_path}: {rel} -> {mem}\n")
                raise SystemExit(2)
            map_entries.append((rel, mem))
            mem_used.add(mem)
            map_paths.add(rel)
            continue
        missing.append(rel)
    if missing:
        sys.stderr.write(f"Missing mapping entries in {map_path}:\n")
        for rel in missing:
            sys.stderr.write(f"  {rel}\n")
        raise SystemExit(2)

seen = {}

def to_member(path):
    base = os.path.basename(path)
    base = os.path.splitext(base)[0]
    base = re.sub(r'[^A-Za-z0-9]', '_', base).upper()
    base = base[:8] if base else 'NONAME'
    mem = base
    if mem in seen:
        h = binascii.crc32(path.encode('utf-8')) & 0xFF
        mem = (base[:6] + f"{h:02X}")[:8]
    seen[mem] = path
    return mem

write_map = use_map != "yes"
if write_map:
    m = open(map_path, 'w', encoding='utf-8')
    m.write('relative_path,member\n')
else:
    m = None
def host_label(rel_path):
    if orig_root in (".", ""):
        return rel_path
    return os.path.normpath(os.path.join(orig_root, rel_path))

# Purpose: load and update sync state to skip unchanged uploads.
# Fixes: repeated uploads of identical content.
# Expected effect: only changed members are sent to FTP unless full_sync is set.
# Impact: upload list is filtered by hash state.
state = {"version": 1, "entries": {}}
if os.path.exists(state_path):
    try:
        with open(state_path, 'r', encoding='utf-8') as sf:
            state = json.load(sf)
    except Exception:
        state = {"version": 1, "entries": {}}
entries_state = state.get("entries", {})

def file_hash(path):
    h = hashlib.sha256()
    with open(path, 'rb') as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()

entries = []
if use_map == "yes":
    for rel_tail, mem in map_entries:
        p = os.path.join(stage_root, rel_tail) if rel_tail else stage_root
        if not os.path.exists(p):
            continue
        entries.append((rel_tail, mem, p))
else:
    for p in files:
        rel = os.path.relpath(p, stage_root)
        mem = to_member(rel)
        if write_map:
            m.write(f"{rel},{mem}\n")
        entries.append((rel, mem, p))

upload_entries = []
for rel_tail, mem, p in entries:
    h = file_hash(p)
    key = f"{pds}:{mem}"
    meta = {
        "hash": h,
        "recfm": recfm,
        "lrecl": lrecl,
        "blksize": blksize,
        "src": host_label(rel_tail),
    }
    old = entries_state.get(key, {})
    if not full_sync:
        if old.get("hash") == h and old.get("recfm") == recfm and old.get("lrecl") == lrecl and old.get("blksize") == blksize:
            entries_state[key] = meta
            continue
    entries_state[key] = meta
    upload_entries.append((rel_tail, mem, p))

state["entries"] = entries_state
with open(state_out, 'w', encoding='utf-8') as sf:
    json.dump(state, sf, ensure_ascii=True, indent=2, sort_keys=True)

with open(ftp_path, 'w', encoding='utf-8') as f, open(list_path, 'w', encoding='utf-8') as lst:
    f.write(f"user {os.environ.get('MF_USER','')} {os.environ.get('MF_PASS','')}\n")
    f.write('passive\n')
    f.write('epsv4\n')
    f.write('quote SITE FILETYPE=SEQ\n')
    f.write(f"quote SITE LRECL={lrecl} RECFM={recfm} BLKSIZE={blksize}\n")
    for rel_tail, mem, p in upload_entries:
        f.write(f"put \"{p}\" '{pds}({mem})'\n")
        lst.write(f"{host_label(rel_tail)} -> {pds}({mem})\n")
    f.write('bye\n')
if m is not None:
    m.close()
PY

# Purpose: skip FTP session when nothing changed to upload.
# Expected effect: no FTP traffic for unchanged trees unless full sync is requested.
UPLOAD_COUNT="$(wc -l <"$TMP_LIST" | awk '{print $1}')"
if [[ "$UPLOAD_COUNT" -eq 0 ]]; then
  mv -f "$TMP_STATE" "$STATE_FILE"
  echo "No changes; 0 files to sync for $PDS"
  exit 0
fi

ftp -inv "$HOST" "$PORT" <"$TMP_FTP" >"$TMP_LOG" 2>&1 || true

ERR_HIT="no"
if rg -a -q "Login failed|Not connected|^530" "$TMP_LOG"; then
  ERR_HIT="yes"
fi

if [[ "$DEBUG" == "yes" ]]; then
  echo "DEBUG: PDS=$PDS RECFM=$RECFM LRECL=$LRECL BLKSIZE=$BLKSIZE MAP=$MAP USE_MAP=$USE_MAP"
  echo "DEBUG: error_pattern_hit=$ERR_HIT"
  sed -E 's/(PASS|pass)[[:space:]]+[^[:space:]]+/PASS ******/' "$TMP_LOG"
fi

if [[ "$ERR_HIT" == "yes" ]]; then
  echo "FTP upload failed for $PDS" >&2
  exit 1
fi

mv -f "$TMP_STATE" "$STATE_FILE"
cat "$TMP_LIST"
if [[ "$DEBUG" == "yes" ]]; then
  echo "DEBUG: list_rc=0"
  echo "DEBUG: end_of_script"
fi
exit 0
