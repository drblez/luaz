# UT_DSREN

## Purpose

Validate `ds.rename` in batch through LUACMD.

## Preconditions

- `DRBLEZ.LUA.TEST(UTDSREN)` exists (from `tests/unit/lua/UTDSREN.lua`).
- `DRBLEZ.LUA.SRC(DS)` exists (from `src/ds.c`, built into LUAEXEC).
- `DRBLEZ.LUA.JCL(UTDSREN)` exists (from `jcl/UTDSREN.jcl`).
- Lua runtime built in `DRBLEZ.LUA.LOADLIB` via `jcl/BUILDINC.jcl`.
- `DRBLEZ.LUA.LOADLIB` and `DRBLEZ.LUA.OBJ` allocated.

## Steps

1) Submit `jcl/UTDSREN.jcl`.
2) Inspect LUAOUT for `LUZ00004` from RUN.

## Expected RC per step

- `PRENEW` = 0
- `ALLOC` = 0
- `RUN` = 0
- `CLEAN` = 0

## Artifacts produced

- `&SYSUID..LUA.TMP.DSREN1` PS dataset (deleted in CLEAN).
- `&SYSUID..LUA.TMP.DSREN2` PS dataset (deleted in CLEAN).
- `DRBLEZ.LUA.TEST(UTDSREN)` Lua unit test member.
