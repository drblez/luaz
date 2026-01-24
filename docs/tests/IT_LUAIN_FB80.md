# IT_LUAIN_FB80

## Purpose

Validate that LUAIN can be supplied as inline FB80 data (JCL in-stream)
and loaded by LUAEXEC when invoked via LUACMD.

## Preconditions

- `DRBLEZ.LUA.LOADLIB(LUAEXEC)` exists.
- `DRBLEZ.LUA.LOADLIB(LUACMD)` exists.

## Steps

1) Submit `jcl/IT_LUAIN_FB80.jcl`.
2) Inspect SYSOUT for `LUZ30090` and argument validation.

## Expected RC per step

- `RUN` = 0

## Artifacts produced

- None.
