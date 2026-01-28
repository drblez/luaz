# UT_DSMEM

## Purpose

Validate `ds.member` formatting in batch through LUACMD.

## Preconditions

- `DRBLEZ.LUA.TEST(UTDMEM)` exists (from `tests/unit/lua/UTDMEM.lua`).
- `DRBLEZ.LUA.SRC(DS)` exists (from `src/ds.c`, built into LUAEXEC).
- `DRBLEZ.LUA.JCL(UTDMEM)` exists (from `jcl/UTDMEM.jcl`).
- Lua runtime built in `DRBLEZ.LUA.LOADLIB` via `jcl/BUILDINC.jcl`.
- `DRBLEZ.LUA.LOADLIB` and `DRBLEZ.LUA.OBJ` allocated.

## Steps

1) Submit `jcl/UTDMEM.jcl`.
2) Inspect LUAOUT for `LUZ00004` from RUN.

## Expected RC per step

- `RUN` = 0

## Artifacts produced

- `DRBLEZ.LUA.TEST(UTDMEM)` Lua unit test member.
