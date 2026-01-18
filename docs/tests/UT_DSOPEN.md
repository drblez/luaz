# UT_DSOPEN

## Purpose

Validate `ds.open_dd` read/write via DDNAME in batch.

## Preconditions

- `DRBLEZ.LUA.SRC(DSUT)` exists (from `src/dsut.c`).
- `DRBLEZ.LUA.SRC(DS)` exists (from `src/ds.c`).
- `DRBLEZ.LUA.LOAD` and `DRBLEZ.LUA.OBJ` allocated.

## Steps

1) Submit `jcl/UTDOPEN.jcl`.
2) Inspect SYSOUT for `LUZ00004` in both RUN and VERIFY steps.

## Expected RC per step

- `ALLOC` = 0
- `GENIN` = 0
- `CCUT` = 0
- `CCDS` = 0
- `LKED` = 0
- `RUN` = 0
- `VERIFY` = 0

## Artifacts produced

- `&&DSIN` temp PS (deleted at end of job).
- `&&DSOUT` temp PS (deleted at end of job).
- `DRBLEZ.LUA.LOAD(DSUT)` load module.
