# UT_TSMSG

## Purpose

Validate `tso.msg` success path in batch through LUACMD (err == nil).

## Preconditions

- `DRBLEZ.LUA.TEST(UTTMSG)` exists (from `tests/unit/lua/UTTMSG.lua`).
- `DRBLEZ.LUA.SRC(TSO)` exists (from `src/tso.c`, built into LUAEXEC).
- `DRBLEZ.LUA.JCL(UTTMSG)` exists (from `jcl/UTTMSG.jcl`).
- Lua runtime built in `DRBLEZ.LUA.LOADLIB` via `jcl/BUILDINC.jcl`.
- `DRBLEZ.LUA.LOADLIB` and `DRBLEZ.LUA.OBJ` allocated.

## Steps

1) Submit `jcl/UTTMSG.jcl`.
2) Inspect LUAOUT for `LUZ00004` from RUN.

## Expected RC per step

- `RUN` = 0

## Artifacts produced

- `DRBLEZ.LUA.TEST(UTTMSG)` Lua unit test member.
