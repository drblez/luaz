# IT_TSO

## Purpose

Validate `tso.cmd(..., true)` output capture in batch mode using a Lua script.

## Preconditions

- `DRBLEZ.LUA.TEST` exists and is readable (RECFM=VB, LRECL>=1024).
- `DRBLEZ.LUA.LOADLIB(LUAEXEC)` exists.
- `DRBLEZ.LUA.LOADLIB(LUACMD)` exists.
- `SYSTSPRT` is allocated in JCL (dataset or SYSOUT).
- `DRBLEZ.LUA.REXX(LUTSO)` is available and `SYSEXEC` is allocated in JCL.

## Steps

1) Upload `tests/integration/lua/ITTSO.lua` into `DRBLEZ.LUA.TEST(ITTSO)`.
2) Submit `jcl/ITTSO.jcl` (it submits `jcl/BUILDINC.jcl` via INTRDR).
3) Inspect SYSOUT for `LUZ00020` and `LUZ30031` output lines.

Alternate (Makefile):

- `make it_tso`

## Expected RC per step

- `RUN` = 0

## Artifacts produced

- None (build artifacts are produced by `jcl/BUILDINC.jcl`).
