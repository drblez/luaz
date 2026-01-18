# UT_LUAPATH

## Purpose

Validate LUAMAP parsing, LUAPATH member lookup, and module load path.

## Preconditions

- `DRBLEZ.LUA.SRC(LUAPUT)` exists (from `src/luaput.c`).
- `DRBLEZ.LUA.LOAD` and `DRBLEZ.LUA.OBJ` allocated.
- `HASHCMP` built (not required for this test).

## Steps

1) Submit `jcl/UTLUPATH.jcl`.
2) Inspect SYSOUT for `LUZ00002`.

## Expected RC per step

- `ALLOC` = 0
- `MAPGEN` = 0
- `SHORT` = 0
- `LONG` = 0
- `CCUT` = 0
- `LKED` = 0
- `RUN` = 0

## Artifacts produced

- `&&LUAPTH` temp PDS (deleted at end of job).
- `DRBLEZ.LUA.LOAD(LUAPUT)` load module.
