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
# | _is_comment_record | function | Detect comment statements |
# | _has_continuation_indicator | function | Detect column-72 continuation flag |
# | _split_sequence_area | function | Split statement/sequence areas |
# | _wrap_comment_record | function | Wrap long comment records |
# | _fix_misaligned_continuation | function | Normalize misaligned continuation markers |
# | _normalize_continuation_line | function | Align continuation lines to operand column |
# | _parse_statement | function | Parse label/opcode/operands/remark |
# | _parse_statement_with_remark_pos | function | Parse statement and remark offset |
# | _split_operands_remark | function | Split operands vs. trailing remark |
# | _split_operands_remark_index | function | Split operands vs. remark with index |
# | _normalize_operands | function | Normalize operand whitespace |
# | _split_operand_chunks | function | Split operands by commas |
# | _split_chunk_by_spaces | function | Split chunks by spaces outside quotes |
# | _wrap_operands | function | Wrap operands to fit statement field |
# | _build_prefix | function | Build label/opcode prefix |
# | _format_statement_parts | function | Format statement with column hints |
# | _iter_files | function | Iterate candidate files by extension |
#
# Notes:
# - Replaces TAB characters with spaces.
# - Writes a .bak backup by default before rewriting a file.
# - Formats statement fields to standard columns (label/opcode/operands).
# - Wraps operands with continuation indicators (column 72).
# - Wraps long comment records and moves long remarks to comment lines.
#
# Platform Requirements:
# - ASCII sources in repo; output stays ASCII (with surrogateescape fallback for safety).

from __future__ import annotations

import argparse
import os
import re
import sys
import textwrap
from pathlib import Path
from typing import Iterable, List, Tuple


TAB_REPLACEMENT = " " * 8
BEGIN_COL = 1
END_COL = 71
CONTINUE_COL = 16
OP_COL = 10
OPERAND_COL = 16
CONTINUATION_COL = 72
CONTINUATION_CHAR = "X"
SEQUENCE_COL = 73
MIN_REMARK_GAP = 2
REMARK_START_OFFSET = MIN_REMARK_GAP + 1
MIN_LABEL_OPCODE_GAP = 1
MIN_OPCODE_OPERAND_GAP = 1
# Use END_COL for the statement field boundary.
MAX_RECORD_LEN = END_COL
COMMENT_PREFIX = "* "
DEFAULT_BACKUP_SUFFIX = ".bak"


_COMMENT_RE = re.compile(r"^(\s*)\*(.*)$")


def _is_comment_record(line: str) -> bool:
    return _COMMENT_RE.match(line) is not None


def _has_continuation_indicator(line: str) -> bool:
    """
    Check for a non-blank continuation indicator in column 72 (standard format).
    """
    if _is_comment_record(line):
        return False
    s = line.rstrip("\n")
    if len(s) > 80:
        return False
    return len(s) >= CONTINUATION_COL and s[CONTINUATION_COL - 1] != " "


def _split_sequence_area(line: str) -> Tuple[str, str]:
    """
    Split statement field (columns 1-72) from sequence area (73+).
    """
    s = line.rstrip("\n")
    if len(s) < SEQUENCE_COL:
        return s, ""
    if len(s) > 80:
        return s, ""
    seq = s[SEQUENCE_COL - 1 :]
    seq_stripped = seq.strip()
    if seq_stripped and not seq_stripped.isdigit():
        return s, ""
    return s[: SEQUENCE_COL - 1], seq


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


def _fix_misaligned_continuation(line: str) -> str:
    """
    Move a trailing single-character continuation marker into column 72.
    """
    if _is_comment_record(line):
        return line
    s = line.rstrip("\n")
    if not s.strip():
        return s
    trimmed = s.rstrip()
    if len(trimmed) < 2:
        return s
    last_idx = len(trimmed) - 1
    last_char = trimmed[last_idx]
    if last_char == " ":
        return s
    if last_idx == CONTINUATION_COL - 1:
        return s
    prev = trimmed[:last_idx].rstrip()
    if not prev:
        return s
    gap = last_idx - len(prev)
    if gap < 2:
        return s
    if len(s) >= SEQUENCE_COL:
        seq_area = s[SEQUENCE_COL - 1 :]
        non_space = [ch for ch in seq_area if ch != " "]
        if len(non_space) > 1:
            return s
        if len(non_space) == 1 and seq_area.strip() != last_char:
            return s
    prev_stripped = prev.rstrip()
    if len(prev_stripped) < OPERAND_COL and not any(ch in prev_stripped for ch in ",()'"):
        return s
    if len(prev_stripped) <= END_COL and not any(ch in prev_stripped for ch in ",()'"):
        return s
    left = prev
    if len(left) > END_COL:
        tail = left[END_COL:]
        if tail.strip():
            return s
        left = left[:END_COL]
    return f"{left.ljust(END_COL)}{last_char}"


def _normalize_continuation_line(line: str) -> str:
    """
    Re-indent continuation lines so operands start in the standard column.
    """
    if _is_comment_record(line):
        return line
    s = line.rstrip("\n")
    body, seq = _split_sequence_area(s)
    cont_char = ""
    if len(body) >= CONTINUATION_COL and body[CONTINUATION_COL - 1] != " ":
        cont_char = body[CONTINUATION_COL - 1]
        body = body[:END_COL]
    payload = body.strip()
    if not payload:
        return s
    new_body = f"{' ' * (OPERAND_COL - 1)}{payload}"
    if len(new_body) > END_COL:
        return s
    if cont_char:
        new_body = f"{new_body.ljust(END_COL)}{cont_char}"
    if seq:
        new_body = f"{new_body.ljust(SEQUENCE_COL - 1)}{seq}"
    return new_body


def _split_operands_remark(text: str) -> Tuple[str, str]:
    """
    Split operands and trailing remark using spaces outside quoted strings.
    """
    if not text:
        return "", ""
    in_quote = False
    i = 0
    while i < len(text) - 1:
        ch = text[i]
        if ch == "'":
            if in_quote and i + 1 < len(text) and text[i + 1] == "'":
                i += 2
                continue
            in_quote = not in_quote
            i += 1
            continue
        if not in_quote and text[i] == " ":
            j = i
            while j < len(text) and text[j] == " ":
                j += 1
            next_idx = j if j < len(text) else -1
            prev_idx = i - 1
            while prev_idx >= 0 and text[prev_idx] == " ":
                prev_idx -= 1
            if next_idx == -1:
                break
            if j - i >= 2:
                return text[:i].rstrip(), text[j:].rstrip()
            prev_char = text[prev_idx] if prev_idx >= 0 else ""
            next_char = text[next_idx]
            if prev_char != "," and next_char != ",":
                return text[:i].rstrip(), text[j:].rstrip()
            i = j
            continue
        i += 1
    return text.rstrip(), ""


def _split_operands_remark_index(text: str) -> Tuple[str, str, int]:
    """
    Split operands and trailing remark, returning remark start index or -1.
    """
    if not text:
        return "", "", -1
    in_quote = False
    i = 0
    while i < len(text) - 1:
        ch = text[i]
        if ch == "'":
            if in_quote and i + 1 < len(text) and text[i + 1] == "'":
                i += 2
                continue
            in_quote = not in_quote
            i += 1
            continue
        if not in_quote and text[i] == " ":
            j = i
            while j < len(text) and text[j] == " ":
                j += 1
            next_idx = j if j < len(text) else -1
            prev_idx = i - 1
            while prev_idx >= 0 and text[prev_idx] == " ":
                prev_idx -= 1
            if next_idx == -1:
                break
            if j - i >= 2:
                return text[:i].rstrip(), text[j:].rstrip(), j
            prev_char = text[prev_idx] if prev_idx >= 0 else ""
            next_char = text[next_idx]
            if prev_char != "," and next_char != ",":
                return text[:i].rstrip(), text[j:].rstrip(), j
            i = j
            continue
        i += 1
    return text.rstrip(), "", -1


def _parse_statement(line: str) -> Tuple[str, str, str, str]:
    """
    Parse label/opcode/operands/remark from a statement line.
    """
    s = line.rstrip("\n")
    label = ""
    rest = s
    if rest and not rest[0].isspace():
        parts = rest.split(None, 1)
        label = parts[0]
        rest = parts[1] if len(parts) > 1 else ""
    else:
        rest = rest.lstrip()
    if not rest:
        return label, "", "", ""
    parts = rest.split(None, 1)
    opcode = parts[0]
    tail = parts[1] if len(parts) > 1 else ""
    operands_raw, remark = _split_operands_remark(tail)
    return label, opcode, operands_raw, remark


def _parse_statement_with_remark_pos(line: str) -> Tuple[str, str, str, str, int]:
    """
    Parse label/opcode/operands/remark and return remark start index.
    """
    s = line.rstrip("\n")
    label = ""
    idx = 0
    if s and not s[0].isspace():
        while idx < len(s) and not s[idx].isspace():
            idx += 1
        label = s[:idx]
    else:
        while idx < len(s) and s[idx].isspace():
            idx += 1
    while idx < len(s) and s[idx].isspace():
        idx += 1
    if idx >= len(s):
        return label, "", "", "", -1
    op_start = idx
    while idx < len(s) and not s[idx].isspace():
        idx += 1
    opcode = s[op_start:idx]
    tail_start = idx
    while tail_start < len(s) and s[tail_start].isspace():
        tail_start += 1
    tail = s[tail_start:]
    operands_raw, remark, remark_idx = _split_operands_remark_index(tail)
    remark_start = tail_start + remark_idx if remark_idx >= 0 else -1
    return label, opcode, operands_raw, remark, remark_start


def _normalize_operands(text: str) -> str:
    """
    Normalize whitespace outside quoted strings and remove spaces around commas.
    """
    if not text:
        return ""
    out: List[str] = []
    in_quote = False
    pending_space = False
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == "'":
            if in_quote and i + 1 < len(text) and text[i + 1] == "'":
                out.append("''")
                i += 2
                continue
            in_quote = not in_quote
            out.append(ch)
            i += 1
            continue
        if in_quote:
            out.append(ch)
            i += 1
            continue
        if ch.isspace():
            pending_space = True
            i += 1
            continue
        if ch == ",":
            if out and out[-1] == " ":
                out.pop()
            out.append(",")
            pending_space = False
            i += 1
            continue
        if pending_space and out:
            out.append(" ")
        pending_space = False
        out.append(ch)
        i += 1
    return "".join(out).strip()


def _split_operand_chunks(text: str) -> List[str]:
    """
    Split operand text into comma-delimited chunks, preserving commas.
    """
    chunks: List[str] = []
    if not text:
        return chunks
    buf: List[str] = []
    in_quote = False
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == "'":
            if in_quote and i + 1 < len(text) and text[i + 1] == "'":
                buf.append("''")
                i += 2
                continue
            in_quote = not in_quote
            buf.append(ch)
            i += 1
            continue
        if ch == "," and not in_quote:
            buf.append(",")
            chunk = "".join(buf).strip()
            if chunk:
                chunks.append(chunk)
            buf = []
            i += 1
            continue
        buf.append(ch)
        i += 1
    tail = "".join(buf).strip()
    if tail:
        chunks.append(tail)
    return chunks


def _split_chunk_by_spaces(text: str) -> List[str]:
    """
    Split a chunk at spaces outside quoted strings, preserving separators.
    """
    if not text:
        return [text]
    pieces: List[str] = []
    buf: List[str] = []
    in_quote = False
    i = 0
    while i < len(text):
        ch = text[i]
        if ch == "'":
            if in_quote and i + 1 < len(text) and text[i + 1] == "'":
                buf.append("''")
                i += 2
                continue
            in_quote = not in_quote
            buf.append(ch)
            i += 1
            continue
        if not in_quote and ch == " ":
            if buf:
                piece = "".join(buf)
                pieces.append(piece)
                buf = []
            i += 1
            while i < len(text) and text[i] == " ":
                i += 1
            if i < len(text):
                buf.append(" ")
            continue
        buf.append(ch)
        i += 1
    if buf:
        pieces.append("".join(buf))
    return pieces


def _wrap_operands(text: str, first_width: int, cont_width: int) -> Tuple[List[str], bool]:
    """
    Wrap operand text into lines that fit the statement field.
    Returns (lines, unbreakable).
    """
    if not text:
        return [""], False
    chunks = _split_operand_chunks(text)
    lines: List[str] = []
    current = ""
    max_len = first_width
    unbreakable = False

    def push_current() -> None:
        nonlocal current, max_len
        if current:
            lines.append(current)
            current = ""
            max_len = cont_width

    for chunk in chunks:
        pieces = [chunk]
        if len(chunk) > max_len:
            pieces = _split_chunk_by_spaces(chunk)
            if len(pieces) == 1 and len(chunk) > max_len:
                unbreakable = True
                break
        for piece in pieces:
            if not current:
                if len(piece) > max_len:
                    unbreakable = True
                    break
                current = piece
            else:
                candidate = f"{current}{piece}"
                if len(candidate) <= max_len:
                    current = candidate
                else:
                    push_current()
                    if len(piece) > max_len:
                        unbreakable = True
                        break
                    current = piece
        if unbreakable:
            break

    if unbreakable:
        return [], True
    if current:
        lines.append(current)
    return lines, False


def _build_prefix(label: str, opcode: str, op_col: int) -> str:
    if label:
        if len(label) <= op_col - (MIN_LABEL_OPCODE_GAP + 1):
            prefix = label.ljust(op_col - 1)
        else:
            prefix = f"{label} "
    else:
        prefix = " " * (op_col - 1)
    return f"{prefix}{opcode}"


def _format_statement_parts(
    raw_line: str,
    label: str,
    opcode: str,
    operands_raw: str,
    remark: str,
    op_col: int,
    operand_col: int,
) -> Tuple[List[str], int, str, int, bool]:
    """
    Return formatted lines, warning count, inline remark, code length, and raw fallback flag.
    """
    s = raw_line.rstrip("\n")
    operands = _normalize_operands(operands_raw)

    prefix = _build_prefix(label, opcode, op_col)
    if len(prefix) > END_COL:
        return [s], 1, "", len(s.rstrip()), True

    operand_lines: List[str] = []
    warn = 0
    if operands:
        if len(prefix) < operand_col - 1:
            prefix_operand = prefix.ljust(operand_col - 1)
        else:
            prefix_operand = f"{prefix} "
        first_width = END_COL - len(prefix_operand)
        cont_width = END_COL - (operand_col - 1)
        operand_lines, unbreakable = _wrap_operands(operands, first_width, cont_width)
        if unbreakable:
            return [s], 1, "", len(s.rstrip()), True
    else:
        prefix_operand = prefix

    remark_lines: List[str] = []
    if remark and operand_lines and len(operand_lines) > 1:
        warn += 1
        remark_lines = _wrap_comment_record("", remark)
        remark = ""

    if operand_lines:
        first_line = f"{prefix_operand}{operand_lines[0]}"
    else:
        first_line = prefix_operand.rstrip()
    if remark:
        if len(remark) > END_COL - REMARK_START_OFFSET:
            warn += 1
            remark_lines = _wrap_comment_record("", remark)
            remark = ""

    stmt_lines: List[str] = [first_line.rstrip()]
    if operand_lines and len(operand_lines) > 1:
        for extra in operand_lines[1:]:
            cont_line = f"{' ' * (OPERAND_COL - 1)}{extra}"
            stmt_lines.append(cont_line.rstrip())

    if len(stmt_lines) > 1:
        with_cont: List[str] = []
        for idx, item in enumerate(stmt_lines):
            if idx < len(stmt_lines) - 1:
                if len(item) > END_COL:
                    return [s], warn + 1, "", len(s.rstrip()), True
                item = f"{item.ljust(END_COL)}{CONTINUATION_CHAR}"
            with_cont.append(item)
        stmt_lines = with_cont

    formatted = [l.rstrip("\n") for l in remark_lines] + stmt_lines
    code_len = len(formatted[0].rstrip()) if formatted else 0
    return formatted, warn, remark, code_len, False


def format_lines(lines: List[str]) -> Tuple[List[str], int]:
    out: List[str] = []
    warnings = 0
    prev_continues = False
    entries: List[dict] = []
    i = 0
    while i < len(lines):
        raw = lines[i].replace("\t", TAB_REPLACEMENT).rstrip("\n")

        if not raw.strip():
            entries.append({"type": "raw", "lines": ["\n"]})
            prev_continues = False
            i += 1
            continue

        if _is_comment_record(raw):
            if len(raw) > MAX_RECORD_LEN:
                m = _COMMENT_RE.match(raw)
                assert m is not None
                prefix, rest = m.group(1), m.group(2)
                text = rest.lstrip()
                entries.append({"type": "raw", "lines": _wrap_comment_record(prefix, text)})
            else:
                entries.append({"type": "raw", "lines": [raw.rstrip() + "\n"]})
            prev_continues = False
            i += 1
            continue

        raw = _fix_misaligned_continuation(raw)
        has_cont = _has_continuation_indicator(raw)
        if prev_continues:
            # Keep multi-line statements intact but re-indent continuation operands.
            norm = _normalize_continuation_line(raw)
            entries.append({"type": "raw", "lines": [norm.rstrip() + "\n"]})
            prev_continues = has_cont
            i += 1
            continue

        body, seq = _split_sequence_area(raw)
        label, opcode, operands_raw, remark, remark_start = _parse_statement_with_remark_pos(body)
        if has_cont and remark_start != -1 and remark_start <= CONTINUATION_COL - 1:
            remark_len = len(remark)
            if not (
                remark_start == CONTINUATION_COL - 1
                and len(body) == CONTINUATION_COL
                and remark_len == 1
            ):
                has_cont = False
        cont_char = ""
        if has_cont and len(body) >= CONTINUATION_COL and body[CONTINUATION_COL - 1] != " ":
            # Preserve explicit continuation markers from the original statement line.
            cont_char = body[CONTINUATION_COL - 1]
            body = body[:END_COL]
            label, opcode, operands_raw, remark, _ = _parse_statement_with_remark_pos(body)
        if not opcode:
            entries.append({"type": "raw_stmt", "lines": [body], "seq": seq})
            i += 1
            continue
        entries.append(
            {
                "type": "stmt",
                "raw": body,
                "label": label,
                "opcode": opcode,
                "operands_raw": operands_raw,
                "remark": remark,
                "seq": seq,
                "cont_char": cont_char,
            }
        )
        prev_continues = has_cont
        i += 1

    def attach_seq_to_lines(lines: List[str], seq: str) -> List[str]:
        if not seq:
            return lines
        for idx, line in enumerate(lines):
            if _is_comment_record(line):
                continue
            padded = line.ljust(SEQUENCE_COL - 1)
            lines[idx] = f"{padded}{seq}"
            break
        return lines
    formatted_items: List[dict] = []
    idx = 0
    while idx < len(entries):
        entry = entries[idx]
        etype = entry["type"]
        if etype in ("raw", "raw_stmt"):
            formatted_items.append(entry)
            idx += 1
            continue
        if etype != "stmt":
            idx += 1
            continue

        block = []
        opcode = entry["opcode"]
        j = idx
        while j < len(entries):
            e = entries[j]
            if e["type"] != "stmt" or e["opcode"] != opcode:
                break
            block.append(e)
            j += 1

        max_label_len = max(len(e["label"]) for e in block)
        max_opcode_len = max(len(e["opcode"]) for e in block)
        op_col = max(OP_COL, max_label_len + MIN_LABEL_OPCODE_GAP + 1)
        # Keep operands in column 16 when possible (standard format requires 1 blank gap).
        operand_col = max(OPERAND_COL, op_col + max_opcode_len + MIN_OPCODE_OPERAND_GAP)

        for e in block:
            lines, warn, remark, code_len, raw_fallback = _format_statement_parts(
                e["raw"],
                e["label"],
                e["opcode"],
                e["operands_raw"],
                e["remark"],
                op_col,
                operand_col,
            )
            warnings += warn
            if e.get("cont_char") and not raw_fallback:
                # Ensure the first line of a continued statement keeps a col-72 marker.
                last = lines[-1]
                if len(last) <= END_COL:
                    lines[-1] = f"{last.ljust(END_COL)}{e['cont_char']}"
            formatted_items.append(
                {
                    "type": "fmt_stmt",
                    "lines": lines,
                    "remark": remark,
                    "seq": e.get("seq", ""),
                    "code_len": code_len,
                    "raw_fallback": raw_fallback,
                }
            )

        idx = j

    remark_entries = [
        e
        for e in formatted_items
        if e.get("type") == "fmt_stmt" and e.get("remark") and not e.get("raw_fallback")
    ]
    if remark_entries:
        base_col = max(e["code_len"] + REMARK_START_OFFSET for e in remark_entries)
    else:
        base_col = 0

    for entry in formatted_items:
        etype = entry["type"]
        if etype == "raw":
            out.extend(entry["lines"])
            continue
        if etype == "raw_stmt":
            lines = entry["lines"][:]
            attach_seq_to_lines(lines, entry.get("seq", ""))
            out.extend([f"{line}\n" for line in lines])
            continue
        if etype != "fmt_stmt":
            continue

        lines = entry["lines"][:]
        seq = entry.get("seq", "")
        remark = entry["remark"]
        code_len = entry["code_len"]
        if remark and not entry["raw_fallback"]:
            max_start = END_COL - len(remark) + 1
            start = base_col
            if start > max_start:
                start = max_start
            min_start = code_len + REMARK_START_OFFSET
            if start < min_start or max_start < min_start:
                warnings += 1
                remark_lines = _wrap_comment_record("", remark)
                out.extend(remark_lines)
                attach_seq_to_lines(lines, seq)
                out.extend([f"{line}\n" for line in lines])
                continue
            final_line = f"{lines[0].rstrip().ljust(start - 1)}{remark}"
            stmt_lines = [final_line.rstrip()]
            attach_seq_to_lines(stmt_lines, seq)
            out.extend([f"{line}\n" for line in stmt_lines])
            continue
        attach_seq_to_lines(lines, seq)
        out.extend([f"{line}\n" for line in lines])

    return out, warnings


def format_file(
    path: Path,
    *,
    check: bool,
    backup: bool,
    backup_suffix: str,
) -> Tuple[bool, int, int]:
    """
    Returns (changed, tabs_found, warnings).
    """
    original_bytes = path.read_bytes()
    text = original_bytes.decode("utf-8", errors="surrogateescape")
    original_lines = text.splitlines(True)

    tabs_found = sum(line.count("\t") for line in original_lines)
    formatted_lines, warnings = format_lines(original_lines)
    formatted_text = "".join(formatted_lines)
    formatted_bytes = formatted_text.encode("utf-8", errors="surrogateescape")

    changed = formatted_bytes != original_bytes
    if changed and not check:
        if backup:
            backup_path = path.with_name(path.name + backup_suffix)
            backup_path.write_bytes(original_bytes)
        path.write_bytes(formatted_bytes)
    return changed, tabs_found, warnings


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
    ap = argparse.ArgumentParser(description="Format HLASM sources (standard columns).")
    ap.add_argument("--root", default=".", help="Root directory to scan")
    ap.add_argument("--ext", action="append", default=[".asm"], help="Extension to format (repeatable)")
    ap.add_argument("--check", action="store_true", help="Check only; do not rewrite files")
    ap.add_argument(
        "--no-backup",
        action="store_true",
        help="Disable .bak backup creation before rewrite",
    )
    ap.add_argument(
        "--backup-suffix",
        default=DEFAULT_BACKUP_SUFFIX,
        help="Backup suffix for rewritten files (default: .bak)",
    )
    ap.add_argument("--quiet", action="store_true", help="Do not print per-file info")
    args = ap.parse_args(argv)

    root = Path(args.root)
    if not root.exists() or not root.is_dir():
        print(f"asmfmt: root not found: {root}", file=sys.stderr)
        return 2

    changed_any = False
    total_changed = 0
    total_tabs = 0
    total_warnings = 0
    for p in sorted(_iter_files(root, args.ext)):
        changed, tabs_found, warnings = format_file(
            p,
            check=args.check,
            backup=not args.no_backup,
            backup_suffix=args.backup_suffix,
        )
        total_tabs += tabs_found
        total_warnings += warnings
        if changed:
            changed_any = True
            total_changed += 1
            if not args.quiet:
                action = "would format" if args.check else "formatted"
                print(f"asmfmt: {action}: {p}")

    if not args.quiet:
        mode = "check" if args.check else "write"
        print(
            f"asmfmt: mode={mode} changed={total_changed} tabs={total_tabs} warnings={total_warnings}"
        )

    return 1 if (args.check and changed_any) else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
