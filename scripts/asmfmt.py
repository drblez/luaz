#!/usr/bin/env python3
# Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
#
# HLASM source formatter used before syncing sources to the mainframe.
#
# Object Table:
# | Object | Kind | Purpose |
# |--------|------|---------|
# | main | function | CLI entry point |
# | format_file | function | Rewrite one ASM file in-place |
# | format_lines | function | Apply formatting rules to a list of lines |
#
# Notes:
# - Replaces TAB characters with spaces.
# - Only rewrites comments when they exceed the configured max length:
#   - Long `* ...` comment records are wrapped into multiple `* ...` records.
#   - Long trailing remarks (after an opcode line) are moved to `* ...` records
#     placed immediately above the opcode line.
# - All other content is left unchanged (aside from TAB replacement).
#
# Platform Requirements:
# - ASCII sources in repo; output stays ASCII (with surrogateescape fallback for safety).

from __future__ import annotations

import argparse
import os
import re
import sys
import textwrap
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Optional, Tuple


TAB_REPLACEMENT = " " * 8
# Use 70 columns to keep spacing margin in LRECL=80 members.
MAX_RECORD_LEN = 70
COMMENT_PREFIX = "* "


@dataclass(frozen=True)
class SplitRemark:
    code: str
    remark: str
    split_at: int


_COMMENT_RE = re.compile(r"^(\s*)\*(.*)$")


def _is_comment_record(line: str) -> bool:
    return _COMMENT_RE.match(line) is not None


def _wrap_comment_record(prefix: str, text: str) -> List[str]:
    """
    Wrap a single comment record (prefix + '*' + text) so that each record stays
    <= MAX_RECORD_LEN.
    """
    usable = MAX_RECORD_LEN - len(prefix) - len(COMMENT_PREFIX)
    if usable < 10:
        usable = 10
    msg = text.strip()
    if not msg:
        return [f"{prefix}*\n"]
    parts = textwrap.wrap(msg, width=usable, break_long_words=False, break_on_hyphens=False)
    return [(f"{prefix}{COMMENT_PREFIX}{p}\n") for p in parts] if parts else [f"{prefix}*\n"]


def _split_code_and_remark(line: str) -> Optional[SplitRemark]:
    """
    Heuristic split for "free-form" HLASM sources in this repo.

    We treat the first run of 2+ spaces (not inside single quotes) that is followed by
    an alphabetic character as the boundary between code and a trailing remark.
    """
    s = line.rstrip("\n")
    if not s.strip():
        return None
    if _is_comment_record(s):
        return None

    def in_single_quote(idx: int) -> bool:
        return (s[:idx].count("'") % 2) == 1

    best: Optional[Tuple[int, int]] = None
    for m in re.finditer(r"\s{2,}", s):
        i = m.start()
        if in_single_quote(i):
            continue
        j = m.end()
        while j < len(s) and s[j] == " ":
            j += 1
        if j >= len(s):
            continue
        if re.match(r"[A-Za-z]", s[j]):
            tail = s[j:].strip()
            # Require at least two words to avoid treating operands as remarks.
            if " " not in tail:
                continue
            best = (i, j)

    if best is None:
        return None
    i, j = best
    return SplitRemark(code=s[:i].rstrip(), remark=s[j:].rstrip(), split_at=i)


def format_lines(lines: List[str]) -> List[str]:
    out: List[str] = []
    i = 0
    while i < len(lines):
        raw = lines[i]
        raw = raw.replace("\t", TAB_REPLACEMENT).rstrip() + "\n"

        if not raw.strip():
            out.append("\n")
            i += 1
            continue

        # Long comment records: wrap into multiple comment records.
        if _is_comment_record(raw) and len(raw.rstrip("\n")) > MAX_RECORD_LEN:
            m = _COMMENT_RE.match(raw.rstrip("\n"))
            assert m is not None
            prefix, rest = m.group(1), m.group(2)
            text = rest.lstrip()
            out.extend(_wrap_comment_record(prefix, text))
            i += 1
            continue

        # Long opcode lines with trailing remarks: move remark above.
        if not _is_comment_record(raw) and len(raw.rstrip("\n")) > MAX_RECORD_LEN:
            split = _split_code_and_remark(raw)
            if split is not None:
                out.extend(_wrap_comment_record("", split.remark))
                out.append(split.code.rstrip() + "\n")
                i += 1
                continue

        # Everything else: leave as-is (aside from TAB replacement).
        out.append(raw)
        i += 1

    return out


def format_file(path: Path, *, check: bool) -> Tuple[bool, int, int]:
    """
    Returns (changed, tabs_found, split_merges).
    """
    original_bytes = path.read_bytes()
    text = original_bytes.decode("utf-8", errors="surrogateescape")
    original_lines = text.splitlines(True)

    tabs_found = sum(line.count("\t") for line in original_lines)
    # Keep metric simple: number of long records that could trigger wrapping/moves.
    split_merges = sum(1 for l in original_lines if len(l.rstrip("\n")) > MAX_RECORD_LEN)

    formatted_lines = format_lines(original_lines)
    formatted_text = "".join(formatted_lines)
    formatted_bytes = formatted_text.encode("utf-8", errors="surrogateescape")

    changed = formatted_bytes != original_bytes
    if changed and not check:
        path.write_bytes(formatted_bytes)
    return changed, tabs_found, split_merges


def _iter_files(root: Path, exts: Iterable[str]) -> Iterable[Path]:
    exts_norm = {e.lower() for e in exts}
    for base, _, names in os.walk(root):
        for name in names:
            p = Path(base) / name
            if not p.is_file():
                continue
            if p.suffix.lower() in exts_norm:
                yield p


def main(argv: List[str]) -> int:
    ap = argparse.ArgumentParser(description="Format HLASM sources (tabs/comments).")
    ap.add_argument("--root", default=".", help="Root directory to scan")
    ap.add_argument("--ext", action="append", default=[".asm"], help="Extension to format (repeatable)")
    ap.add_argument("--check", action="store_true", help="Check only; do not rewrite files")
    ap.add_argument("--quiet", action="store_true", help="Do not print per-file info")
    args = ap.parse_args(argv)

    root = Path(args.root)
    if not root.exists() or not root.is_dir():
        print(f"asmfmt: root not found: {root}", file=sys.stderr)
        return 2

    changed_any = False
    total_changed = 0
    total_tabs = 0
    total_merges = 0
    for p in sorted(_iter_files(root, args.ext)):
        changed, tabs_found, merges = format_file(p, check=args.check)
        total_tabs += tabs_found
        total_merges += merges
        if changed:
            changed_any = True
            total_changed += 1
            if not args.quiet:
                action = "would format" if args.check else "formatted"
                print(f"asmfmt: {action}: {p}")

    if not args.quiet:
        mode = "check" if args.check else "write"
        print(
            f"asmfmt: mode={mode} changed={total_changed} tabs={total_tabs} long_records={total_merges}"
        )

    return 1 if (args.check and changed_any) else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
