# UT_DSREM

## Purpose

Validate `ds.remove` in batch through LUACMD.

## Preconditions

- `DRBLEZ.LUA.TEST(UTDSREM)` exists (from `tests/unit/lua/UTDSREM.lua`).
- `DRBLEZ.LUA.SRC(DS)` exists (from `src/ds.c`, built into LUAEXEC).
- `DRBLEZ.LUA.JCL(UTDSREM)` exists (from `jcl/UTDSREM.jcl`).
- Lua runtime built in `DRBLEZ.LUA.LOADLIB` via `jcl/BUILDINC.jcl`.
- `DRBLEZ.LUA.LOADLIB` and `DRBLEZ.LUA.OBJ` allocated.

## Steps

1) Submit `jcl/UTDSREM.jcl`.
2) Inspect LUAOUT for `LUZ00004` from RUN.

## Expected RC per step

- `ALLOC` = 0
- `RUN` = 0
- `CLEAN` = 0

## Artifacts produced

- `&SYSUID..LUA.TMP.DSREM` PS dataset (deleted in CLEAN).
- `DRBLEZ.LUA.TEST(UTDSREM)` Lua unit test member.
