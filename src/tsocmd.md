# tsocmd.asm IBM References

## ceeentry-amode-rmode

- `CEEENTRY` accepts `AMODE=` and `RMODE=` parameters and emits the
  module prolog; avoid standalone AMODE/RMODE pseudo-ops to prevent
  duplicate mode settings when `CEEENTRY` expands.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=macros-ceeentry-macro-generate-language-environment-conforming-prolog

## ceeentry-auto

- `CEEENTRY` supports `AUTO=` to reserve automatic storage in the LE
  DSA; this storage can be referenced via `CEEDSAAUTO` in the CEEDSA
  mapping.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=macros-ceeentry-macro-generate-language-environment-conforming-prolog
