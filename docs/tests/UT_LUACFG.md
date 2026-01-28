# UT_LUACFG

## Purpose

Validate LUACFG parsing and policy access via `luaz_policy_load`.

## Preconditions

- `DRBLEZ.LUA.SRC(LUACFGUT)` exists (from `src/luacfg_ut.c`).
- `DRBLEZ.LUA.SRC(POLICY)` exists (from `src/policy.c`).
- `DRBLEZ.LUA.JCL(UTBLD)` exists (from `jcl/UTBLD.jcl`).
- `DRBLEZ.LUA.LOAD` allocated.
- LUACFG content is provided in-stream by `jcl/UT_LUACFG.jcl`.

## Steps

1) Submit `jcl/UT_LUACFG.jcl`.
2) Inspect SYSOUT for `LUZ00040`.

## Expected RC per step

- `UTBLD` = 0 (CC1/CC2/LKED)
- `RUN` = 0

## Artifacts produced

- `DRBLEZ.LUA.LOAD(LUACFGUT)` load module.
