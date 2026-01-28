# IT_LUACFG

## Purpose

Validate LUACFG-driven runtime configuration and LUAZ_CONFIG exposure in Lua.

## Preconditions

- `DRBLEZ.LUA.TEST(ITLUACFG)` exists (from `tests/integration/lua/ITLUACFG.lua`).
- `DRBLEZ.LUA.LOADLIB` is available to `TSOLIB ACTIVATE` in batch TMP.
- `LUACMD` is available in `DRBLEZ.LUA.LOADLIB` or LNKLST.

## Steps

1) Submit `jcl/IT_LUACFG.jcl`.
2) Inspect CFGOUT/SYSOUT for `LUZ00042`.

## Expected RC per step

- `RUN` = 0

## Artifacts produced

- None (spool output only).
