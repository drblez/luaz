# IT_TSO

## Purpose

Validate `tso.cmd(..., true)` output capture in batch mode using a Lua script.

## Preconditions

- `DRBLEZ.LUA.TEST` exists and is readable (RECFM=VB, LRECL>=1024).
- `DRBLEZ.LUA.LOADLIB(LUAEXEC)` exists.
- `DRBLEZ.LUA.LOADLIB(LUACMD)` exists.
- `SYSTSPRT` is allocated in JCL (dataset or SYSOUT).
- `DRBLEZ.LUA.REXX(LUTSO)` is available and `SYSEXEC` is allocated in JCL.
- `TSOOUT` is allocated dynamically by `LUTSO` (no JCL DD needed).
- `LUAOUT` is allocated in JCL to capture Lua output.
- `LUACFG` is provided (in-stream) to configure policy defaults.

## Steps

1) Upload `tests/integration/lua/ITTSO.lua` into `DRBLEZ.LUA.TEST(ITTSO)`.
2) Submit `jcl/ITTSO.jcl` (it submits `jcl/BUILDINC.jcl` via INTRDR).
3) Inspect LUAOUT for `LUZ30031`, `LUZ00022`, `LUZ00023`, `LUZ00024` and SYSPRINT for `LUZ00020`.

Alternate (Makefile):

- `make it_tso`

## Expected RC per step

- `RUN` = 0

## Artifacts produced

- None (build artifacts are produced by `jcl/BUILDINC.jcl`).
