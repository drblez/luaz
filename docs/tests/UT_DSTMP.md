# UT_DSTMP

## Purpose

Validate `ds.tmpname` format in batch through LUACMD.

## Preconditions

- `DRBLEZ.LUA.TEST(UTDSTMP)` exists (from `tests/unit/lua/UTDSTMP.lua`).
- `DRBLEZ.LUA.SRC(DS)` exists (from `src/ds.c`, built into LUAEXEC).
- `DRBLEZ.LUA.JCL(UTDSTMP)` exists (from `jcl/UTDSTMP.jcl`).
- Lua runtime built in `DRBLEZ.LUA.LOADLIB` via `jcl/BUILDINC.jcl`.
- `DRBLEZ.LUA.LOADLIB` and `DRBLEZ.LUA.OBJ` allocated.

## Steps

1) Submit `jcl/UTDSTMP.jcl`.
2) Inspect LUAOUT for `LUZ00004` from RUN.

## Expected RC per step

- `RUN` = 0

## Artifacts produced

- `DRBLEZ.LUA.TEST(UTDSTMP)` Lua unit test member.
