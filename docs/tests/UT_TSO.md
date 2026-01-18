# UT_TSO

## Purpose

Validate `tso` module stubs return LUZ-coded errors.

## Preconditions

- `DRBLEZ.LUA.SRC(TSOUT)` exists (from `src/tsout.c`).
- Lua VM objects are already built in `DRBLEZ.LUA.OBJ` (see `jcl/BUILDLUA.jcl`).
- `DRBLEZ.LUA.JCL(UTBLD)` exists (from `jcl/UTBLD.jcl`).
- `DRBLEZ.LUA.LOAD` allocated.

## Steps

1) Submit `jcl/UTTSO.jcl`.
2) Inspect SYSOUT for `LUZ00011`.

## Expected RC per step

- `UTBLD` = 0 (CC1/CC2/LKED)
- `RUN` = 0

## Artifacts produced

- `DRBLEZ.LUA.LOAD(TSOUT)` load module.
