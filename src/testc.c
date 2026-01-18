/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Minimal C compile/link smoke test for MVS build pipeline.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | main   | func | Emit a prefixed message and return success |
 */
#include <stdio.h>

int main(void)
{
  puts("LUZ00001 TESTC build smoke test OK");
  return 0;
}
