#!/usr/bin/env python3
import argparse
import binascii
import os
import re
import sys
from pathlib import Path

EXTS_SRC = {".c", ".cc", ".cpp", ".cxx", ".s", ".S", ".asm"}
EXTS_INC = {".h", ".hh", ".hpp", ".hxx"}


def sanitize(name: str) -> str:
    name = re.sub(r"[^A-Za-z0-9]", "_", name)
    return name.upper() or "NONAME"


def member_for(path: str, used: dict) -> str:
    base = Path(path).stem
    base = sanitize(base)
    if len(base) <= 8 and base not in used:
        used[base] = path
        return base

    crc = binascii.crc32(path.encode("utf-8")) & 0xFFF  # 3 hex digits
    for i in range(4096):
        cand = (base[:5] + f"{(crc + i) & 0xFFF:03X}")[:8]
        other = used.get(cand)
        if other is None:
            used[cand] = path
            return cand
        if other == path:
            return cand

    raise RuntimeError(f"No unique member for {path}")


def collect_files(roots, exts):
    files = []
    for root in roots:
        for p in Path(root).rglob("*"):
            if p.is_file() and p.suffix in exts:
                files.append(p)
    return sorted(files)


def main():
    ap = argparse.ArgumentParser(description="Generate PDS member mapping.")
    ap.add_argument("--root", action="append", required=True, help="Root directory (repeatable)")
    ap.add_argument("--out", required=True, help="Output CSV path")
    ap.add_argument("--kind", choices=["src", "inc"], required=True)
    args = ap.parse_args()

    exts = EXTS_SRC if args.kind == "src" else EXTS_INC
    files = collect_files(args.root, exts)
    used = {}

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as f:
        f.write("relative_path,member\n")
        for p in files:
            rel = os.path.relpath(p, Path.cwd())
            mem = member_for(rel, used)
            f.write(f"{rel},{mem}\n")

    print(f"mapped {len(files)} files -> {out_path}")
    print(f"unique members: {len(used)}")

if __name__ == "__main__":
    main()
