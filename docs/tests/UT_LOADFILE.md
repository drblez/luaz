# UT_LOADFILE

## Purpose

Validate `luaL_loadfile` uses `LUAPATH` on z/OS.

## Preconditions

- `DRBLEZ.LUA.SRC(LUAFUT)` exists (from `src/luafut.c`).
- Lua VM objects are already built in `DRBLEZ.LUA.OBJ` (incremental build).
- `DRBLEZ.LUA.JCL(UTBLD)` exists (from `jcl/UTBLD.jcl`).
- `DRBLEZ.LUA.LOAD` allocated.

## Steps

1) Submit `jcl/UTLOADF.jcl`.
2) Inspect SYSOUT for `LUZ00009`.

## Expected RC per step

- `ALLOC` = 0
- `SHORT` = 0
- `UTBLD` = 0 (CC1/LKED)
- `RUN` = 0

## Artifacts produced

- `&&LUAPTH` temp PDS (deleted at end of job).
- `DRBLEZ.LUA.LOAD(LUAFUT)` load module.
