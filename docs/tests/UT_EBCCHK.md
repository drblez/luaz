# UT_EBCCHK

## Purpose

Validate ASCII->EBCDIC conversion for FTP-transferred C and ASM sources by
printing the byte codes of the literal "ABC".

## Preconditions

- `&HLQ..LUA.SRC(EBCCHK)` exists (from `src/ebcchk.c`).
- `&HLQ..LUA.ASM(EBCCHKA)` exists (from `src/ebcchka.asm`).
- `&HLQ..LUA.OBJ` and `&HLQ..LUA.LOADLIB` are writable.

## Steps

1) Sync sources and JCL (for example, run `scripts/ftp_sync_all.sh`).
2) Submit `jcl/UT_EBCCHK.jcl`.
3) Check SYSOUT/SYSPRINT for `LUZ40080` (C bytes) and JESMSGLG for `LUZ40081`
   (ASM bytes).

## Expected RC per step

- `CC1` = 0
- `AA1` = 0
- `LKEDC` = 0
- `LKEDA` = 0
- `RUNC` = 0
- `RUNA` = 0

## Artifacts produced

- `&HLQ..LUA.OBJ(EBCCHK)`
- `&HLQ..LUA.OBJ(EBCCHKA)`
- `&HLQ..LUA.LOADLIB(EBCCHK)`
- `&HLQ..LUA.LOADLIB(EBCCHKA)`
