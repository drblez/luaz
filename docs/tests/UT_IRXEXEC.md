# UT_IRXEXEC

## Purpose
Validate that IRXEXEC can be called from C in batch using a minimal exec from SYSEXEC.

## Artifacts
- JCL: `jcl/UTIRX.jcl`
- Source: `src/irxut.c`

## Setup
- Ensure `DRBLEZ.LUA.SRC(IRXUT)` and `DRBLEZ.LUA.OBJ` exist.
- `SYS1.LPALIB` must be available to resolve `IRXEXEC`.

## Expected Results
- Job completes with `RC=0`.
- `SYSTSPRT` contains:
  - `LUZ00013 IRXEXEC UT OK`
- If failure occurs, `SYSTSPRT` contains:
  - `LUZ00014 IRXEXEC UT failed: ...`

## Notes
- The test creates a temporary SYSEXEC PDS with member `HELLO`.
- `HELLO` returns the numeric argument so IRXUT expects REXX RC=3.
