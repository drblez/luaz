# tsoeftr.asm IBM References

## ceeentry-amode-rmode

- `CEEENTRY` accepts `AMODE=` and `RMODE=` parameters and emits the
  module prolog; avoid standalone AMODE/RMODE pseudo-ops to prevent
  duplicate mode settings when `CEEENTRY` expands.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=macros-ceeentry-macro-generate-language-environment-conforming-prolog
