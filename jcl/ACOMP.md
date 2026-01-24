# ACOMP: ASMA90 options

## asm-options

Purpose: use IBM-documented assembler options to produce richer SYSPRINT
output for debugging (listing + cross-reference + low-severity messages).

Options applied in ACOMP:
- LIST: emit listing output.
- XREF(SHORT,UNREFS): emit cross-reference tables per IBM syntax.
- FLAG(0): include all message severities in listing output.

IBM documentation (HLASM Programmer's Guide / XREF option):
- https://www.ibm.com/docs/en/zos/2.1.0?topic=ao-xref-1

Notes:
- These options are applied in `jcl/ACOMP.jcl` ASMA90 PARM.
- No SYSADATA output is requested; only SYSPRINT/SYSOUT is used.
