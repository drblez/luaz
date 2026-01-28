# UT_DSOPEN

## Purpose

Validate `ds.open_dd` read/write via DDNAME in batch through LUACMD.

## Preconditions

- `DRBLEZ.LUA.TEST(UTDOPEN)` exists (from `tests/unit/lua/UTDOPEN.lua`).
- `DRBLEZ.LUA.SRC(DS)` exists (from `src/ds.c`, built into LUAEXEC).
- `DRBLEZ.LUA.JCL(UTDOPEN)` exists (from `jcl/UTDOPEN.jcl`).
- Lua runtime built in `DRBLEZ.LUA.LOADLIB` via `jcl/BUILDINC.jcl`.
- `DRBLEZ.LUA.LOADLIB` and `DRBLEZ.LUA.OBJ` allocated.

## Steps

1) Submit `jcl/UTDOPEN.jcl`.
2) Inspect LUAOUT for `LUZ00004` from RUN.

## Expected RC per step

- `ALLOC` = 0
- `GENIN` = 0
- `RUN` = 0

## Artifacts produced

- `&&DSIN` temp PS (deleted at end of job).
- `&&DSOUT` temp PS (deleted at end of job).
- `DRBLEZ.LUA.TEST(UTDOPEN)` Lua unit test member.
