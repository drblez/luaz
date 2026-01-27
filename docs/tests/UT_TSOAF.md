# UT_TSOAF

## Purpose

Validate DAIR alloc/free wrappers (TSODALC/TSODFRE) using a clean C test driver.

## Preconditions

- `DRBLEZ.LUA.SRC(TSOCALF)` exists (from `src/tso_c_alloc_free.c`).
- `DRBLEZ.LUA.ASM(TSODAIR)` exists (from `src/tsodair.asm`).
- `DRBLEZ.LUA.LOADLIB` allocated.
- `SYSTSPRT` is allocated in JCL (dataset recommended for stable DCB).
- `TSOAFLOG` DD is allocated in JCL (temp FB dataset in `UTTSOAF`).

## Steps

1) Submit `jcl/UTTSOAF.jcl`.
2) Inspect SYSOUT for:
   - `LUZ00030` (start),
   - `LUZ00031` (IKJTSOEV),
   - `LUZ00032` (TSODALC),
   - `LUZ00033` (IKJEFTSR),
   - `LUZ00035` (captured lines),
   - `LUZ00036` (TSODFRE),
   - no `LUZ00037`.
3) If RUN fails, check `PRTLOG` and `PRTSPRT` output in SYSOUT.

## Expected RC per step

- `LKED` = 0
- `RUN` = 0

## Artifacts produced

- `DRBLEZ.LUA.LOAD(TSOCALF)` load module.
