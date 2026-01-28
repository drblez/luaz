# UT_TSAF

## Purpose

Validate `tso.alloc`/`tso.free` error behavior in batch through LUACMD.

## Preconditions

- `DRBLEZ.LUA.TEST(UTTAF)` exists (from `tests/unit/lua/UTTAF.lua`).
- `DRBLEZ.LUA.SRC(TSO)` exists (from `src/tso.c`, built into LUAEXEC).
- `DRBLEZ.LUA.JCL(UTTAF)` exists (from `jcl/UTTAF.jcl`).
- Lua runtime built in `DRBLEZ.LUA.LOADLIB` via `jcl/BUILDINC.jcl`.
- `DRBLEZ.LUA.LOADLIB` and `DRBLEZ.LUA.OBJ` allocated.

## Steps

1) Submit `jcl/UTTAF.jcl`.
2) Inspect LUAOUT for `LUZ00004` from RUN.

## Expected RC per step

- `RUN` = 0

## Notes

- This UT expects `tso.alloc` and `tso.free` to return a non-nil error
  table with `luz=30033/30034` until native DAIR parsing is implemented.

## Artifacts produced

- `DRBLEZ.LUA.TEST(UTTAF)` Lua unit test member.
