# UT_C2A

## Purpose

Validate C->ASM OS-linkage parameter passing and return codes for non-XPLINK.

## Preconditions

- `&HLQ..LUA.SRC(C2ATEST)` exists.
- `&HLQ..LUA.ASM(C2AASM)` exists.
- `&HLQ..LUA.OBJ` and `&HLQ..LUA.LOADLIB` are writable.

## Steps

1) Sync sources and JCL (for example, run `scripts/ftp_sync_all.sh`).
2) Submit `jcl/UT_C2A.jcl`.
3) Inspect SYSOUT/SYSPRINT for `LUZ40100`..`LUZ40109`.

## Expected RC per step

- `CC1` = 0
- `AA1` = 0
- `LKED` = 0
- `RUNC` = 0

## Artifacts produced

- `&HLQ..LUA.OBJ(C2ATEST)`
- `&HLQ..LUA.OBJ(C2AASM)`
- `&HLQ..LUA.LOADLIB(C2ATEST)`
