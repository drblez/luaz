#!/usr/bin/env python3
# Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
#
# Build a download plan for JES spool files.
#
# Object Table:
# | Object | Kind | Purpose |
# |--------|------|---------|
# | main | function | Parse JES DIR output and emit download plan |
#
# Notes:
# - Output plan format: JESID|OUTPATH|STEP|DDNAME
# - Output list format: OUTPATH (one per line)

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


LINE_RE = re.compile(r"^\s*(\d{3})\s+")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build JES spool download plan.")
    parser.add_argument("--jobid", required=True, help="JOBnnnnn")
    parser.add_argument("--jobname", required=True, help="JOBNAME")
    parser.add_argument("--dirlist", required=True, help="FTP dir output file")
    parser.add_argument("--outdir", required=True, help="Output directory")
    parser.add_argument("--plan", required=True, help="Plan output file")
    parser.add_argument("--outputs", required=True, help="Output list file")
    parser.add_argument("--include-sysudump", action="store_true")
    return parser.parse_args()


def build_step_label(step: str, procstep: str) -> str:
    if procstep and procstep != "N/A":
        return f"{step}_{procstep}"
    return step


def main() -> int:
    args = parse_args()
    jobid = args.jobid.strip()
    jobname = args.jobname.strip()
    outdir = Path(args.outdir)

    plan_lines: list[str] = []
    outputs: list[str] = []
    used_out = set()
    found = 0

    with open(args.dirlist, "r", encoding="utf-8", errors="replace") as fh:
        for line in fh:
            match = LINE_RE.match(line)
            if not match:
                continue
            parts = line.split()
            if len(parts) >= 6 and re.match(r"^[A-Z]$", parts[3]):
                jes_id, step, procstep, _cls, ddname, _bytes = parts[:6]
            elif len(parts) >= 5 and re.match(r"^[A-Z]$", parts[2]):
                jes_id, step, _cls, ddname, _bytes = parts[:5]
                procstep = "N/A"
            else:
                continue
            found += 1
            if ddname == "SYSUDUMP" and not args.include_sysudump:
                continue
            step_label = build_step_label(step, procstep)
            jes_full = f"{jobid}.{jes_id}"
            out_name = f"{jobname}_{jobid}_{step_label}_{ddname}.out"
            out_path = outdir / out_name
            if str(out_path) in used_out:
                out_path = outdir / f"{jobname}_{jobid}_{step_label}_{ddname}_ID{jes_id}.out"
            used_out.add(str(out_path))
            plan_lines.append(f"{jes_full}|{out_path}|{step_label}|{ddname}")
            outputs.append(str(out_path))

    if found == 0:
        print(f"No spool entries parsed in {args.dirlist}", file=sys.stderr)
        return 2

    if not plan_lines:
        print(f"No spool entries after filtering in {args.dirlist}", file=sys.stderr)
        return 2

    with open(args.plan, "w", encoding="utf-8") as ph:
        for line in plan_lines:
            ph.write(line + "\n")

    with open(args.outputs, "w", encoding="utf-8") as oh:
        for line in outputs:
            oh.write(line + "\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
