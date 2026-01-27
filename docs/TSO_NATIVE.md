# TSO Native Backend (C-first)

This document captures the IBM references and the intended native (non‑REXX) path for `tso.*`.

## IBM references (authoritative)

- TSO/E Programming Services overview (IKJEFTSR, DAIR/DAIRFAIL, GETMSG, IKJTBLS).
- IKJTSOEV summary of supported services (IKJEFTSR, DAIR/DAIRFAIL, IKJTBLS, message handling).
- IKJEFTSR parameter list (flags, parameter meanings, CPPL/token usage).
- DAIRFAIL (IKJEFF18) parameter list mapping macro (IKJEFFDF in SYS1.MACLIB).
- TMP (IKJEFT01/1A/1B) background execution reference.

Links (IBM Docs):
- https://www.ibm.com/docs/en/zos/3.2.0?topic=introduction-overview-tsoe-programming-services
- https://www.ibm.com/docs/en/zos/3.2.0?topic=ikjtsoev-summary-tsoe-services-available-under
- https://www.ibm.com/docs/en/zos/2.4.0?topic=ikjeftsr-parameter-list
- https://www.ibm.com/docs/en/zos/3.2.0?topic=dairfail-parameter-list
- https://www.ibm.com/docs/SSLTBW_3.1.0/com.ibm.zos.v3r1.ikjb400/tmpbtch.htm

## Intended service usage

- `tso.cmd` -> IKJEFTSR (TSO/E Service Facility)
  - Execute TSO commands directly from C when `capture=false`.
  - Output capture reads `SYSTSPRT` directly (no DAIR redirection).
  - CPPL is forwarded when available for OS-linkage calls.
- `tso.alloc` / `tso.free` -> DAIR + DAIRFAIL
  - Dynamic allocation interface with diagnostic mapping.
  - DAIR calls use ASM macro wrappers (IKJDAPL/IKJDAP08/IKJDAP18) to avoid C struct drift.
- `tso.msg` -> SYSTSPRT (or message service)
  - Optional GETMSG for buffered message retrieval when needed.

## IKJEFTSR parameter list (summary)

Per IBM, IKJEFTSR receives a parameter list with:
1) a **fullword flags** parameter where:
   - byte 2 selects **authorized (X'00')** vs **unauthorized (X'01')** environment,
   - byte 3 selects **dump on abend** (X'01') or **no dump** (X'00'),
   - byte 4 selects **function type** (command/CLIST/REXX vs program). citeturn0search4turn0search1
2) a **command/program string** (for commands, includes parameters),
3) **string length**,
4) **output RC** (initialized to -1 by IKJEFTSR),
5) **output reason/abend code** (meaning depends on IKJEFTSR RC),
6) **output abend code**,
7) optional **program parameter list** (only for program invocation),
8) optional **CPPL** (required for unauthorized invocations in some cases),
9) optional **IKJEFTSI token**. citeturn1view0

**Batch I/O:** foreground uses terminal; background uses **SYSTSIN** for input and **SYSTSPRT** for output. citeturn1view0

For a working assembler example (IKJEFTSI/IKJEFTSR/IKJEFTST), see IBM sample program in the docs. citeturn0search3

## DAIR/DAIRFAIL parameter lists

DAIR usage is described in the TSO/E Programming Services overview; DAIRFAIL (IKJEFF18) is used to analyze DAIR/SVC 99 return codes. citeturn0search1turn7view0

- **DAIRFAIL (IKJEFF18) parameter list** is mapped by `IKJEFFDF` in SYS1.MACLIB and contains pointers to the failing request and return codes. citeturn3search4
- **DAIR parameter list** is defined by the `IKJDAIR` macro in SYS1.MACLIB; we will extract and document it from the system macro to avoid transcription errors.

Local macro extracts:
- `docs/TSO_NATIVE_IKJDAPL.txt`
- `docs/TSO_NATIVE_IKJDAP00.txt`
- `docs/TSO_NATIVE_IKJDAP04.txt`
- `docs/TSO_NATIVE_IKJDAP08.txt`
- `docs/TSO_NATIVE_IKJDAP10.txt`
- `docs/TSO_NATIVE_IKJDAP14.txt`
- `docs/TSO_NATIVE_IKJDAP18.txt`
- `docs/TSO_NATIVE_IKJEFFDF.txt`
- `docs/TSO_NATIVE_IKJCPPL.txt`

Key DAIR request blocks (from the extracted macros):
- **DAPB08 (IKJDAP08)**: allocate dataset (new/old/mod/shr) with space, unit, volser, dsorg, etc.
- **DAPB18 (IKJDAP18)**: unallocate dataset or DDNAME with optional disposition override.

## Implementation notes

- DSNAME buffer format: 2-byte length followed by 44-byte blank-padded name (see IBM docs for DAIR entry code X'00').
- DA08PQTY/DA08SQTY field format and DA08CD/DA18CD entry codes must be verified against IBM DAIR docs before finalizing production defaults.
- ASM wrappers: `TSODALC`/`TSODFRE` in `src/tsodair.asm` support legacy DAIR allocation for
  STACK-based capture experiments (not used by current `tso.cmd`).
- `TSODALC` uses `DA08ALN=SYSTSPRT` with `DA08ATRL` to inherit DCB attributes; confirm with IBM DAIR docs.
- Interim capture path: when `tso.cmd(..., true)` is used, `LUTSO` (REXX) traps
  command output with `OUTTRAP` and emits it to `SYSTSPRT`, which is then read
  by C to return only the new lines.

## Notes

- The native backend still requires a valid TSO/E environment.
- `tso.cmd` depends on JCL-allocated `SYSTSPRT` (dataset or SYSOUT).
- `tso.cmd(..., true)` returns only new `SYSTSPRT` output since the last call in the
  same process (per-call output isolation).
- All messages must use `LUZNNNNN` prefix and be registered in `MSGS-*.md`.
