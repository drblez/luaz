# UT_HASHCMP — HASHCMP Unit Test

JCL: `jcl/UTHASH.jcl`

## Purpose

Validate HASHCMP compare/update behavior for CRC32:
missing hash ⇒ RC≠0, update ⇒ RC=0, compare after update ⇒ RC=0,
source change ⇒ RC≠0, update ⇒ RC=0, final compare ⇒ RC=0.

## Preconditions

- `DRBLEZ.LUA.LOAD(HASHCMP)` exists.
- No active locks on `DRBLEZ.TST.HASH.SRC` or `DRBLEZ.TST.HASH.HASH`.

## Steps

1) Allocate test PDSEs (`DRBLEZ.TST.HASH.SRC`, `DRBLEZ.TST.HASH.HASH`).
2) Write member `TEST1` with initial content.
3) Compare (expect non‑zero RC).
4) Update (expect RC=0).
5) Compare (expect RC=0).
6) Modify source member.
7) Compare (expect non‑zero RC).
8) Update (expect RC=0).
9) Final compare (expect RC=0).

## Expected RC per step

- `CMP1`: RC≠0
- `UPD1`: RC=0
- `CMP2`: RC=0
- `CMP3`: RC≠0
- `UPD2`: RC=0
- `CMP4`: RC=0

## Artifacts

- `DRBLEZ.TST.HASH.SRC(TEST1)`
- `DRBLEZ.TST.HASH.HASH(TEST1)`
