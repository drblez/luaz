/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Native TSO command unit test helper.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | main | function | Execute a TSO command via native backend |
 *
 * User Actions:
 * - Run under a TSO-capable environment (TMP/IKJEFT01).
 * - Allocate SYSTSPRT for command output.
 */
#include "tso_native.h"

#include <stdio.h>

int main(void)
{
  int rc = 0;

  puts("LUZ00022 TSNUT start");
  rc = tso_native_cmd("TIME", NULL);
  if (rc != 0) {
    printf("LUZ00023 TSNUT failed rc=%d\n", rc);
    return 8;
  }
  puts("LUZ00022 TSNUT ok");
  return 0;
}
