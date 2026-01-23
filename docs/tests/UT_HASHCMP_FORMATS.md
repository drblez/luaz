# UT_HASHCMP_FORMATS

## Purpose

Validate HASHCMP behavior for FB vs VB source record formats.

## Preconditions

- HASHCMP load module is available in `&HLQ..LUA.LOAD`.

## Steps

1. Allocate temporary FB/VB source PDS, hash PDS, and OBJ PDS.
2. Create identical members in FB and VB source datasets.
3. Update hashes for FB and VB sources (expect RC=0).
4. Compare FB source with FB hash (expect RC=0).
5. Compare VB source with VB hash (expect RC=0).
6. Cross-compare FB source with VB hash (expect RC=0).
7. Cross-compare VB source with FB hash (expect RC=0).

## Expected RC per step

- ALLOC: 0
- MKFB/MKVB/MKOBJ: 0
- UFB/UVB: 0
- CFB/CVB: 0
- XFB/XVB: 0

## Artifacts produced

- Temporary datasets only (allocated with `&&`, auto-cleaned).
