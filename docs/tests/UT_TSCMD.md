# UT_TSCMD

## Purpose

Validate `tso.cmd` no-capture path in batch through LUACMD (err == nil).

## Preconditions

- `DRBLEZ.LUA.TEST(UTTCMD)` exists (from `tests/unit/lua/UTTCMD.lua`).
- `DRBLEZ.LUA.SRC(TSO)` exists (from `src/tso.c`, built into LUAEXEC).
- `DRBLEZ.LUA.JCL(UTTCMD)` exists (from `jcl/UTTCMD.jcl`).
- Lua runtime built in `DRBLEZ.LUA.LOADLIB` via `jcl/BUILDINC.jcl`.
- `DRBLEZ.LUA.LOADLIB` and `DRBLEZ.LUA.OBJ` allocated.

## Steps

1) Submit `jcl/UTTCMD.jcl`.
2) Inspect LUAOUT for `LUZ00004` from RUN.

## Expected RC per step

- `RUN` = 0

## Artifacts produced

- `DRBLEZ.LUA.TEST(UTTCMD)` Lua unit test member.
