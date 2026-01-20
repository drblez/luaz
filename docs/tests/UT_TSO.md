# UT_TSO

## Purpose

Validate `tso` module C bindings and REXX bridge.

## Preconditions

- `DRBLEZ.LUA.SRC(TSOUT)` exists (from `src/tsout.c`).
- `DRBLEZ.LUA.REXX(LUTSO)` uploaded and allocated to `SYSEXEC`.
- Lua VM objects are already built in `DRBLEZ.LUA.OBJ` (incremental build).
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
