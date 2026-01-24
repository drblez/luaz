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
 * - No user DDNAME setup is required for output capture.
 * - Ensure TSOAUTH is available in SYS1.LINKLIB for command processor testing.
 */
#include "TSONATV"

#include <stdio.h>

int main(void)
{
  int rc = 0;
  int reason = 0;
  int abend = 0;
  int dair_rc = 0;
  int cat_rc = 0;
  char ddname[9];

  puts("LUZ00022 TSNUT start");
  rc = tso_native_cmd_cp("TIME", ddname, sizeof(ddname),
                         &reason, &abend, &dair_rc, &cat_rc);
  if (rc != 0) {
    printf("LUZ00023 TSNUT failed rc=%d reason=%d abend=%d dair_rc=%d cat_rc=%d\n",
           rc, reason, abend, dair_rc, cat_rc);
    if (ddname[0] != '\0')
      tso_native_cmd_cleanup(ddname);
    return 8;
  }
  if (tso_native_cmd_cleanup(ddname) != 0) {
    printf("LUZ00023 TSNUT failed rc=%d reason=%d abend=%d dair_rc=%d cat_rc=%d\n",
           rc, reason, abend, dair_rc, cat_rc);
    return 8;
  }
  puts("LUZ00022 TSNUT ok");
  return 0;
}
