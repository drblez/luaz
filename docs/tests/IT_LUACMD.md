# IT_LUACMD

## Purpose

Validate that LUACMD invokes LUAEXEC via LUAEXRUN, injects MODE=TSO
automatically, and preserves user operands.

## Preconditions

- `DRBLEZ.LUA.LOADLIB(LUAEXEC)` exists.
- `DRBLEZ.LUA.LOADLIB(LUACMD)` exists.
- `DRBLEZ.LUA.TEST` exists and is readable (RECFM=VB, LRECL>=1024).

## Steps

1) Upload `tests/integration/lua/ITLUACMD.lua` into `DRBLEZ.LUA.TEST(ITLUACMD)`.
2) Submit `jcl/IT_LUACMD.jcl` (run under IKJEFT01, passes ARG1/'ARG TWO'/ARG3=Z/ARG4).
3) Inspect LUAOUT for `LUZ30070` and argument validation.

## Expected RC per step

- `RUN` = 0

## Artifacts produced

- None.
