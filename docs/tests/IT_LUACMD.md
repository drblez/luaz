# IT_LUACMD

## Purpose

Validate that LUACMD invokes LUAEXEC via LUAEXRUN and forces MODE=TSO.

## Preconditions

- `DRBLEZ.LUA.LOADLIB(LUAEXEC)` exists.
- `DRBLEZ.LUA.LOADLIB(LUACMD)` exists.
- `DRBLEZ.LUA.TEST` exists and is readable (RECFM=VB, LRECL>=1024).

## Steps

1) Upload `tests/integration/lua/ITLUACMD.lua` into `DRBLEZ.LUA.TEST(ITLUACMD)`.
2) Submit `jcl/IT_LUACMD.jcl` (run under IKJEFT01).
3) Inspect SYSOUT for `LUZ30070`.

## Expected RC per step

- `RUN` = 0

## Artifacts produced

- None.
