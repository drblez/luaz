# ICOMP: CCNDRVR listing options

## cc-options

Purpose: use IBM-documented compiler listing options to provide focused
SYSPRINT output for debugging (source and cross-reference) without
ASM-like listing sections.

Options applied in ICOMP (via OPTFILE DD:CCOPTS):
- TERM
- RENT
- LANGLVL(EXTC99)
- LONGNAME
- NOASM
- NOGENASM
- NOXPLINK
- DEFINE(LUAZ_ZOS)
- SOURCE
- XREF

IBM documentation (z/OS XL C compiler listing components):
- https://www.ibm.com/docs/en/zos/2.5.0?topic=listing-zos-xl-c-compiler-components

Notes:
- Options are stored in `&HLQ..LUA.CTL(CCOPTS)` by `jcl/BUILDINC.jcl`.
- `jcl/ICOMP.jcl` uses `OPTFILE(DD:CCOPTS)` to load them.
- Output goes to SYSPRINT/SYSCPRT (no additional DDs required).
- SOURCE and XREF are documented listing components; LIST is omitted to
  keep C listings limited to source and cross-reference sections.
