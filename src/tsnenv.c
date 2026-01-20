/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Native TSO environment unit test helper.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | main | function | Validate TSO environment via IKJTSOEV |
 *
 * User Actions:
 * - Run under a TSO-capable environment (TMP/IKJEFT01).
 * - Allocate SYSTSPRT to capture diagnostic output.
 */
#include "tso_native.h"

#include <stdio.h>

int main(void)
{
  int rc = 0;

  puts("LUZ00024 TSNENV start");
  rc = tso_native_env_init();
  if (rc != 0) {
    printf("LUZ00025 TSNENV failed rc=%d\n", rc);
    return 8;
  }
  puts("LUZ00024 TSNENV ok");
  return 0;
}
