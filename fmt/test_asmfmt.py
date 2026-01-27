#!/usr/bin/env python3
# Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
#
# HLASM formatter tests.
#
# Object Table:
# | Object | Kind | Purpose |
# |--------|------|---------|
# | TestAsmFmt | class | Unit tests for asmfmt formatting rules |
# | _extract_operands | function | Rebuild operand string from formatted lines |
# | _make_continuation_line | function | Build a line with a continuation flag |
# | main | function | CLI entry point |
#
# Platform Requirements:
# - ASCII sources only.

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from scripts import asmfmt


def _extract_operands(lines: list[str]) -> str:
    """
    Rebuild operand string from formatted lines using standard columns.
    """
    parts: list[str] = []
    for idx, raw in enumerate(lines):
        line = raw.rstrip("\n")
        stmt = line[: asmfmt.END_COL]
        start = asmfmt.OPERAND_COL - 1
        chunk = stmt[start:].rstrip()
        parts.append(chunk)
    return "".join(parts).strip()


def _make_continuation_line(text: str) -> str:
    """
    Build a line with a continuation indicator in column 72.
    """
    padded = text.ljust(asmfmt.END_COL)
    return f"{padded}{asmfmt.CONTINUATION_CHAR}\n"


class TestAsmFmt(unittest.TestCase):
    """Unit tests for the HLASM formatter."""

    def test_basic_alignment(self) -> None:
        """Label/opcode/operand alignment uses standard columns."""
        out, warnings = asmfmt.format_lines(["R1  EQU  1\n"])
        self.assertEqual(warnings, 0)
        line = out[0].rstrip("\n")
        self.assertEqual(line.find("EQU") + 1, asmfmt.OP_COL)
        self.assertEqual(line[asmfmt.OPERAND_COL - 1], "1")

    def test_labelless_alignment(self) -> None:
        """Opcode/operand alignment works without a label."""
        out, warnings = asmfmt.format_lines([" L   R1,FOO\n"])
        self.assertEqual(warnings, 0)
        line = out[0].rstrip("\n")
        self.assertEqual(line[asmfmt.OP_COL - 1], "L")
        self.assertEqual(line[asmfmt.OPERAND_COL - 1], "R")

    def test_continuation_wrapping(self) -> None:
        """Operands wrap with a continuation indicator in column 72."""
        operands = (
            "AREA1(10),AREA2(10),AREA3(10),AREA4(10),AREA5(10),"
            "AREA6(10),AREA7(10),AREA8(10),AREA9(10),AREA10(10)"
        )
        out, warnings = asmfmt.format_lines([f" MVC {operands}\n"])
        self.assertEqual(warnings, 0)
        self.assertGreater(len(out), 1)
        for line in out[:-1]:
            stmt = line.rstrip("\n")
            self.assertGreaterEqual(len(stmt), asmfmt.CONTINUATION_COL)
            self.assertEqual(stmt[asmfmt.CONTINUATION_COL - 1], asmfmt.CONTINUATION_CHAR)
        last = out[-1].rstrip("\n")
        if len(last) >= asmfmt.CONTINUATION_COL:
            self.assertEqual(last[asmfmt.CONTINUATION_COL - 1], " ")
        rebuilt = _extract_operands(out)
        self.assertEqual(rebuilt, asmfmt._normalize_operands(operands))

    def test_unbreakable_literal_warning(self) -> None:
        """Long literals are left unchanged and emit warnings."""
        literal = "C'" + ("A" * 120) + "'"
        line = f"LONGOP DC {literal}\n"
        out, warnings = asmfmt.format_lines([line])
        self.assertEqual(warnings, 1)
        self.assertEqual(out[0], line)

    def test_sequence_area_preserved(self) -> None:
        """Sequence area (columns 73-80) is preserved on the first line."""
        seq = "12345678"
        base = "R2 EQU 2"
        line = base.ljust(72) + seq + "\n"
        out, warnings = asmfmt.format_lines([line])
        self.assertEqual(warnings, 0)
        self.assertEqual(out[0].rstrip("\n")[72:80], seq)

    def test_backup_creation(self) -> None:
        """format_file creates a .bak file with the original content."""
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "sample.asm"
            original = b"R1\tEQU\t1\n"
            path.write_bytes(original)
            changed, _, warnings = asmfmt.format_file(
                path,
                check=False,
                backup=True,
                backup_suffix=".bak",
            )
            self.assertTrue(changed)
            self.assertEqual(warnings, 0)
            backup = Path(tmp) / "sample.asm.bak"
            self.assertTrue(backup.exists())
            self.assertEqual(backup.read_bytes(), original)

    def test_split_sequence_area_bounds(self) -> None:
        """Sequence split honors length bounds."""
        short = "R1 EQU 1"
        body, seq = asmfmt._split_sequence_area(short)
        self.assertEqual(body, short)
        self.assertEqual(seq, "")
        long = "A" * 81
        body, seq = asmfmt._split_sequence_area(long)
        self.assertEqual(body, long)
        self.assertEqual(seq, "")
        line = "R2 EQU 2".ljust(72) + "SEQ00001"
        body, seq = asmfmt._split_sequence_area(line)
        self.assertEqual(seq, "")

    def test_has_continuation_indicator(self) -> None:
        """Continuation detection respects column 72 and length limits."""
        cont = _make_continuation_line(" MVC A,B")
        self.assertTrue(asmfmt._has_continuation_indicator(cont))
        no_cont = " MVC A,B".ljust(asmfmt.END_COL) + " \n"
        self.assertFalse(asmfmt._has_continuation_indicator(no_cont))
        comment = "* COMMENT".ljust(asmfmt.END_COL) + "X\n"
        self.assertFalse(asmfmt._has_continuation_indicator(comment))
        too_long = ("X" * 81) + "\n"
        self.assertFalse(asmfmt._has_continuation_indicator(too_long))
        crooked = " MVC A,B".ljust(70) + "X\n"
        self.assertFalse(asmfmt._has_continuation_indicator(crooked))
        single_operand = "R1  EQU  1\n"
        self.assertFalse(asmfmt._has_continuation_indicator(single_operand))

    def test_wrap_comment_record(self) -> None:
        """Comment wrapping handles empty and long text."""
        empty = asmfmt._wrap_comment_record("", "")
        self.assertEqual(empty, ["*\n"])
        prefix = "X" * 62
        wrapped_prefix = asmfmt._wrap_comment_record(prefix, "TEXT")
        self.assertEqual(len(wrapped_prefix), 1)
        text = "WORD " * 20
        wrapped = asmfmt._wrap_comment_record("", text)
        self.assertGreater(len(wrapped), 1)
        for line in wrapped:
            self.assertTrue(line.startswith("* "))
            self.assertLessEqual(len(line.rstrip("\n")), asmfmt.MAX_RECORD_LEN)
        comment = "*" + ("A" * 80)
        out, warnings = asmfmt.format_lines([comment + "\n"])
        self.assertEqual(warnings, 0)
        self.assertEqual(len(out), 1)

    def test_split_operands_remark_quotes(self) -> None:
        """Operand/remark split ignores spaces inside quotes."""
        ops, remark = asmfmt._split_operands_remark("A,'B  C'  REMARK")
        self.assertEqual(ops, "A,'B  C'")
        self.assertEqual(remark, "REMARK")
        ops, remark = asmfmt._split_operands_remark("A,'B''C'  TAIL")
        self.assertEqual(ops, "A,'B''C'")
        self.assertEqual(remark, "TAIL")
        ops, remark = asmfmt._split_operands_remark("A, B")
        self.assertEqual(ops, "A, B")
        self.assertEqual(remark, "")
        ops, remark = asmfmt._split_operands_remark("A, B REM")
        self.assertEqual(ops, "A, B")
        self.assertEqual(remark, "REM")

    def test_normalize_operands(self) -> None:
        """Whitespace normalization keeps quoted content intact."""
        raw = " A , B ,C , 'D , E'  F  "
        normalized = asmfmt._normalize_operands(raw)
        self.assertEqual(normalized, "A, B,C,'D , E' F")
        doubled = "A,'B''C' ,D"
        normalized = asmfmt._normalize_operands(doubled)
        self.assertEqual(normalized, "A,'B''C',D")

    def test_split_operand_chunks_quotes(self) -> None:
        """Chunk splitting ignores commas inside quotes."""
        chunks = asmfmt._split_operand_chunks("A,'B,C',D")
        self.assertEqual(chunks, ["A,", "'B,C',", "D"])
        empty = asmfmt._split_operand_chunks("")
        self.assertEqual(empty, [])
        chunks = asmfmt._split_operand_chunks("A,'B''C',D")
        self.assertEqual(chunks, ["A,", "'B''C',", "D"])

    def test_split_chunk_by_spaces(self) -> None:
        """Chunk splitting preserves space separators."""
        pieces = asmfmt._split_chunk_by_spaces("A  B C")
        self.assertEqual(pieces, ["A", " B", " C"])
        empty = asmfmt._split_chunk_by_spaces("")
        self.assertEqual(empty, [""])
        pieces = asmfmt._split_chunk_by_spaces("'A''B'  C")
        self.assertEqual(pieces, ["'A''B'", " C"])

    def test_wrap_operands_empty(self) -> None:
        """Wrapping empty operands returns a blank line."""
        lines, unbreakable = asmfmt._wrap_operands("", 10, 10)
        self.assertFalse(unbreakable)
        self.assertEqual(lines, [""])
        lines, unbreakable = asmfmt._wrap_operands("TOOLONG", 3, 3)
        self.assertTrue(unbreakable)
        self.assertEqual(lines, [])
        lines, unbreakable = asmfmt._wrap_operands("AA BBCCCCCC", 5, 5)
        self.assertTrue(unbreakable)

    def test_build_prefix_long_label(self) -> None:
        """Long labels do not force fixed opcode column."""
        prefix = asmfmt._build_prefix("LONG_LABEL", "MVC", asmfmt.OP_COL)
        self.assertEqual(prefix, "LONG_LABEL MVC")
        prefix = asmfmt._build_prefix("VERYLONGLABEL", "MVC", asmfmt.OP_COL)
        self.assertTrue(prefix.startswith("VERYLONGLABEL "))

    def test_format_statement_basics(self) -> None:
        """Statement formatting returns lines and remark when needed."""
        label, opcode, ops, remark = asmfmt._parse_statement("ONLYOP DS")
        lines, warn, inline_remark, _, _ = asmfmt._format_statement_parts(
            "ONLYOP DS",
            label,
            opcode,
            ops,
            remark,
            asmfmt.OP_COL,
            asmfmt.OPERAND_COL,
        )
        self.assertEqual(warn, 0)
        self.assertEqual(len(lines), 1)
        self.assertEqual(inline_remark, "")
        label, opcode, ops, remark = asmfmt._parse_statement("LABELONLY")
        self.assertEqual(opcode, "")
        label, opcode, ops, remark = asmfmt._parse_statement("L" * 80 + " MVC")
        lines, warn, inline_remark, _, _ = asmfmt._format_statement_parts(
            "L" * 80 + " MVC",
            label,
            opcode,
            ops,
            remark,
            asmfmt.OP_COL,
            asmfmt.OPERAND_COL,
        )
        self.assertEqual(warn, 1)
        self.assertEqual(inline_remark, "")
        line = " MVC A,B  " + ("R" * 80)
        label, opcode, ops, remark = asmfmt._parse_statement(line)
        lines, warn, inline_remark, _, _ = asmfmt._format_statement_parts(
            line,
            label,
            opcode,
            ops,
            remark,
            asmfmt.OP_COL,
            asmfmt.OPERAND_COL,
        )
        self.assertGreaterEqual(warn, 1)
        self.assertEqual(inline_remark, "")

    def test_format_lines_continuation_passthrough(self) -> None:
        """Continuation lines keep markers while aligning operands."""
        first = _make_continuation_line(" MVC A,B")
        second = "               C\n"
        out, warnings = asmfmt.format_lines([first, second])
        self.assertEqual(warnings, 0)
        self.assertEqual(out[0].rstrip("\n")[asmfmt.OP_COL - 1], "M")
        self.assertEqual(out[0].rstrip("\n")[asmfmt.OPERAND_COL - 1], "A")
        self.assertTrue(asmfmt._has_continuation_indicator(out[0]))
        self.assertEqual(out[1].rstrip("\n")[asmfmt.OPERAND_COL - 1], "C")
        comment = "* COMMENT".ljust(asmfmt.END_COL + 1) + "\n"
        out, warnings = asmfmt.format_lines([comment, "\n"])
        self.assertEqual(warnings, 0)
        self.assertTrue(out[0].startswith("*"))
        crooked = " MVC A,B".ljust(70) + "X\n"
        out, warnings = asmfmt.format_lines([crooked, "               C\n"])
        self.assertEqual(warnings, 0)
        self.assertTrue(asmfmt._has_continuation_indicator(out[0]))
        self.assertEqual(out[0].rstrip("\n")[asmfmt.CONTINUATION_COL - 1], "X")
        self.assertEqual(out[1].rstrip("\n")[asmfmt.OPERAND_COL - 1], "C")
        beyond = " MVC A,B".ljust(75) + "Z\n"
        out, warnings = asmfmt.format_lines([beyond])
        self.assertEqual(warnings, 0)
        self.assertTrue(asmfmt._has_continuation_indicator(out[0]))
        self.assertEqual(out[0].rstrip("\n")[asmfmt.CONTINUATION_COL - 1], "Z")
        short = " MVC A,B X\n"
        out, warnings = asmfmt.format_lines([short])
        self.assertEqual(warnings, 0)
        self.assertFalse(asmfmt._has_continuation_indicator(out[0]))
        line = " MVC A,B  X\n"
        out, warnings = asmfmt.format_lines([line])
        self.assertEqual(warnings, 0)
        self.assertTrue(asmfmt._has_continuation_indicator(out[0]))
        equ_line = "R1  EQU  1\n"
        out, warnings = asmfmt.format_lines([equ_line])
        self.assertEqual(warnings, 0)
        self.assertFalse(asmfmt._has_continuation_indicator(out[0]))

    def test_misaligned_continuation_multiline(self) -> None:
        """Misaligned continuation markers are fixed across multiple lines."""
        lines = [
            "SNAPXPL  SNAPX  MF=L,DCB=SNAPDCB,ID=1,PDATA=(REGS,PSW,SAH),            +\n",
            "         STORAGE=(SNAPTRC_START,SNAPTRC_END,  +\n",
            "         SNAPLUA_START,SNAPLUA_END)\n",
        ]
        out, warnings = asmfmt.format_lines(lines)
        self.assertEqual(warnings, 0)
        self.assertEqual(len(out), 3)
        self.assertTrue(asmfmt._has_continuation_indicator(out[0]))
        self.assertTrue(asmfmt._has_continuation_indicator(out[1]))
        self.assertFalse(asmfmt._has_continuation_indicator(out[2]))
        self.assertEqual(out[0].rstrip("\n")[asmfmt.CONTINUATION_COL - 1], "+")
        self.assertEqual(out[1].rstrip("\n")[asmfmt.CONTINUATION_COL - 1], "+")
        self.assertEqual(out[0].rstrip("\n")[asmfmt.OPERAND_COL - 1], "M")
        self.assertEqual(out[1].rstrip("\n")[asmfmt.OPERAND_COL - 1], "S")
        self.assertEqual(out[2].rstrip("\n")[asmfmt.OPERAND_COL - 1], "S")

    def test_misaligned_continuation_long_prefix(self) -> None:
        """Continuation markers beyond column 72 are moved into place."""
        line = " MVC A,B".ljust(90) + "+\n"
        out, warnings = asmfmt.format_lines([line])
        self.assertEqual(warnings, 0)
        self.assertTrue(asmfmt._has_continuation_indicator(out[0]))
        self.assertEqual(out[0].rstrip("\n")[asmfmt.CONTINUATION_COL - 1], "+")

    def test_remark_alignment_across_file(self) -> None:
        """Inline remarks align to a single column when possible."""
        lines = [
            "L1  EQU  1  FIRST\n",
            "L2  EQU  22  SECOND\n",
            "L3  DC   F'1'  THIRD\n",
        ]
        out, warnings = asmfmt.format_lines(lines)
        self.assertEqual(warnings, 0)
        first = out[0].rstrip("\n")
        second = out[1].rstrip("\n")
        third = out[2].rstrip("\n")
        first_col = first.index("FIRST")
        second_col = second.index("SECOND")
        third_col = third.index("THIRD")
        self.assertEqual(first_col, second_col)
        self.assertEqual(first_col, third_col)
        gap = 0
        idx = first_col - 1
        while idx >= 0 and first[idx] == " ":
            gap += 1
            idx -= 1
        self.assertGreaterEqual(gap, asmfmt.MIN_REMARK_GAP)

    def test_remark_shift_left(self) -> None:
        """Long remarks shift left while keeping max gap where possible."""
        lines = [
            "L1  EQU  1  SHORT\n",
            "L2  EQU  22  " + ("R" * 50) + "\n",
        ]
        out, warnings = asmfmt.format_lines(lines)
        self.assertEqual(warnings, 0)
        first = out[0].rstrip("\n")
        second = out[1].rstrip("\n")
        first_col = first.index("SHORT")
        second_col = second.index("R")
        self.assertGreaterEqual(first_col, second_col)

    def test_remark_overflow_repaired(self) -> None:
        """Inline remarks that spill past column 71 move before the statement."""
        remark = "WORD " * 20
        line = f"LABEL DS 0H  {remark}\n"
        out, warnings = asmfmt.format_lines([line])
        self.assertGreaterEqual(warnings, 1)
        self.assertGreaterEqual(len(out), 2)
        self.assertTrue(any(line.startswith("* ") for line in out))
        stmt_idx = next(idx for idx, line in enumerate(out) if not line.startswith("* "))
        stmt = out[stmt_idx].rstrip("\n")
        if len(stmt) >= asmfmt.CONTINUATION_COL:
            self.assertEqual(stmt[asmfmt.CONTINUATION_COL - 1], " ")
        self.assertNotIn("WORD", stmt)

    def test_block_opcode_alignment(self) -> None:
        """Opcodes align within same-opcode blocks only."""
        lines = [
            "SHORT DS F  ONE\n",
            "LONG_LABEL_NAME DS F  TWO\n",
            "NEXTOP DC F'1'  THREE\n",
            "X DC F'2'  FOUR\n",
        ]
        out, warnings = asmfmt.format_lines(lines)
        self.assertEqual(warnings, 0)
        ds1 = out[0].rstrip("\n")
        ds2 = out[1].rstrip("\n")
        dc1 = out[2].rstrip("\n")
        dc2 = out[3].rstrip("\n")
        self.assertEqual(ds1.index("DS"), ds2.index("DS"))
        self.assertEqual(dc1.index("DC"), dc2.index("DC"))
        self.assertNotEqual(ds1.index("DS"), dc1.index("DC"))

    def test_format_file_check_mode(self) -> None:
        """Check mode does not rewrite files or create backups."""
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "check.asm"
            original = b"R1\tEQU\t1\n"
            path.write_bytes(original)
            changed, _, _ = asmfmt.format_file(
                path,
                check=True,
                backup=True,
                backup_suffix=".bak",
            )
            self.assertTrue(changed)
            self.assertFalse((Path(tmp) / "check.asm.bak").exists())
            self.assertEqual(path.read_bytes(), original)

    def test_iter_files(self) -> None:
        """File iterator filters by extension."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "a.asm").write_text("X\n", encoding="utf-8")
            (root / "b.ASM").write_text("X\n", encoding="utf-8")
            (root / "c.txt").write_text("X\n", encoding="utf-8")
            (root / "d.asm").mkdir()
            found = sorted(p.name for p in asmfmt._iter_files(root, [".asm"]))
            self.assertEqual(found, ["a.asm", "b.ASM"])

    def test_main_missing_root(self) -> None:
        """Main returns 2 when root directory is missing."""
        rc = asmfmt.main(["--root", "nonexistent_dir_asmfmt_test"])
        self.assertEqual(rc, 2)

    def test_main_check_mode(self) -> None:
        """Main returns 1 in check mode when formatting would change files."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "a.asm").write_text("R1\tEQU\t1\n", encoding="utf-8")
            rc = asmfmt.main(["--root", str(root), "--ext", ".asm", "--check", "--quiet"])
            self.assertEqual(rc, 1)
            rc = asmfmt.main(["--root", str(root), "--ext", ".asm"])
            self.assertEqual(rc, 0)


def main() -> int:
    """CLI entry point."""
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestAsmFmt)
    result = unittest.TextTestRunner().run(suite)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
