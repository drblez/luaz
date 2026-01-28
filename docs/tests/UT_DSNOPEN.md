# UT_DSNOPEN

## Purpose

Validate `ds.open_dsn` read/write via DSN path in batch through LUACMD.

## Preconditions

- `DRBLEZ.LUA.TEST(UTDSNOP)` exists (from `tests/unit/lua/UTDSNOPEN.lua`).
- `DRBLEZ.LUA.SRC(DS)` exists (from `src/ds.c`, built into LUAEXEC).
- `DRBLEZ.LUA.JCL(UTDSNOP)` exists (from `jcl/UTDSNOPEN.jcl`).
- Lua runtime built in `DRBLEZ.LUA.LOADLIB` via `jcl/BUILDINC.jcl`.
- `DRBLEZ.LUA.LOADLIB` and `DRBLEZ.LUA.OBJ` allocated.

## Steps

1) Submit `jcl/UTDSNOPEN.jcl`.
2) Inspect LUAOUT for `LUZ00004` from RUN.

## Expected RC per step

- `PRECLN` = 0
- `ALLOCIN` = 0
- `GENIN` = 0
- `ALLOCOT` = 0
- `RUN` = 0
- `CLEAN` = 0

## Artifacts produced

- `&SYSUID..LUA.TMP.DSNIN` PS dataset (deleted in CLEAN).
- `&SYSUID..LUA.TMP.DSNOUT` PS dataset (deleted in CLEAN).
- `DRBLEZ.LUA.TEST(UTDSNOP)` Lua unit test member.
