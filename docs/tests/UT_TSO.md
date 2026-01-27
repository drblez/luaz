# UT_TSO

## Purpose

Validate `tso` module C bindings and `tso.cmd` behavior with optional capture.

## Preconditions

- `DRBLEZ.LUA.SRC(TSOUT)` exists (from `src/tsout.c`).
- `DRBLEZ.LUA.SRC(TSONATV)` exists (from `src/tso_native.c`).
- `DRBLEZ.LUA.ASM(TSODAIR)` uploaded for DAIR wrapper assembly (alloc/free only).
- `DRBLEZ.LUA.REXX(LUTSO)` optional (required for `tso.cmd(..., true)` capture).
- Lua VM objects are already built in `DRBLEZ.LUA.OBJ` (incremental build).
- `DRBLEZ.LUA.JCL(UTBLD)` exists (from `jcl/UTBLD.jcl`).
- `DRBLEZ.LUA.LOAD` allocated.
- `SYSTSPRT` is allocated in JCL (dataset or SYSOUT).
- `SYSEXEC` DD must be allocated when testing `tso.cmd(..., true)` capture.

## Steps

1) Submit `jcl/UTTSO.jcl`.
2) Inspect SYSOUT for `LUZ00011` and `LUZ30031` lines.

## Expected RC per step

- `UTBLD` = 0 (CC1/CC2/LKED)
- `RUN` = 0

## Artifacts produced

- `DRBLEZ.LUA.LOAD(TSOUT)` load module.
