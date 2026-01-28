# UT_DSINF

## Purpose

Validate `ds.info` metadata in batch through LUACMD.

## Preconditions

- `DRBLEZ.LUA.TEST(UTDSINF)` exists (from `tests/unit/lua/UTDSINF.lua`).
- `DRBLEZ.LUA.SRC(DS)` exists (from `src/ds.c`, built into LUAEXEC).
- `DRBLEZ.LUA.JCL(UTDSINF)` exists (from `jcl/UTDSINF.jcl`).
- Lua runtime built in `DRBLEZ.LUA.LOADLIB` via `jcl/BUILDINC.jcl`.
- `DRBLEZ.LUA.LOADLIB` and `DRBLEZ.LUA.OBJ` allocated.

## Steps

1) Submit `jcl/UTDSINF.jcl`.
2) Inspect LUAOUT for `LUZ00004` from RUN.

## Expected RC per step

- `ALLOC` = 0
- `RUN` = 0
- `CLEAN` = 0

## Artifacts produced

- `&SYSUID..LUA.TMP.DSINF` PS dataset (deleted in CLEAN).
- `DRBLEZ.LUA.TEST(UTDSINF)` Lua unit test member.
