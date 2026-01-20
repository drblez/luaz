# IT_TSO

## Purpose

Validate the `tso` module end-to-end in batch mode using a Lua script.

## Preconditions

- `DRBLEZ.LUA.REXX(LUTSO)` uploaded and allocated to `SYSEXEC`.
- `DRBLEZ.LUA.TEST` exists and is readable (for `tso.alloc`/`tso.free`).
- `DRBLEZ.LUA.SRC(LUAIT)` exists (from `src/luait.c`).
- Lua VM objects are already built in `DRBLEZ.LUA.OBJ` (incremental build).
- `DRBLEZ.LUA.JCL(UTBLD)` exists (from `jcl/UTBLD.jcl`).

## Steps

1) Upload `tests/integration/lua/ITTSO.lua` into `DRBLEZ.LUA.TEST(ITTSO)`.
2) Submit `jcl/ITTSO.jcl`.
3) Inspect SYSOUT for `LUZ00020`.

## Expected RC per step

- `UTBLD` = 0 (CC1/CC2/LKED)
- `RUN` = 0

## Artifacts produced

- `DRBLEZ.LUA.LOAD(LUAIT)` load module.
