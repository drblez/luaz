# IT_TSO

## Purpose

Validate the `tso` module end-to-end in batch mode using a Lua script.

## Preconditions

- `DRBLEZ.LUA.REXX(LUTSO)` optional (REXX fallback only).
- `DRBLEZ.LUA.TEST` exists and is readable (RECFM=VB, LRECL>=1024).
- `DRBLEZ.LUA.LOADLIB(LUAEXEC)` exists.
- `DRBLEZ.LUA.LOADLIB(LUACMD)` exists.

## Steps

1) Upload `tests/integration/lua/ITTSO.lua` into `DRBLEZ.LUA.TEST(ITTSO)`.
2) Submit `jcl/ITTSO.jcl` (it submits `jcl/BUILDINC.jcl` via INTRDR).
3) Inspect SYSOUT for `LUZ00020`.

## Expected RC per step

- `RUN` = 0

## Artifacts produced

- None (build artifacts are produced by `jcl/BUILDINC.jcl`).
