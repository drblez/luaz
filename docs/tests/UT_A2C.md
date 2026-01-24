# UT_A2C

## Purpose

Validate ASM->C OS-linkage parameter passing and return codes for non-XPLINK.

## Preconditions

- `&HLQ..LUA.SRC(A2CCALL)` exists.
- `&HLQ..LUA.ASM(A2CTEST)` exists.
- `&HLQ..LUA.OBJ` and `&HLQ..LUA.LOADLIB` are writable.

## Steps

1) Sync sources and JCL (for example, run `scripts/ftp_sync_all.sh`).
2) Submit `jcl/UT_A2C.jcl`.
3) Inspect JESMSGLG for `LUZ40110`..`LUZ40119`.

## Expected RC per step

- `CC1` = 0
- `AA1` = 0
- `LKED` = 0
- `RUNA` = 0

## Artifacts produced

- `&HLQ..LUA.OBJ(A2CCALL)`
- `&HLQ..LUA.OBJ(A2CTEST)`
- `&HLQ..LUA.LOADLIB(A2CTEST)`
