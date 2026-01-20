/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Authorized TSO launcher stub.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | main | function | Run a minimal native TSO command via authorized module |
 *
 * User Actions:
 * - Ensure module is linked with AC=1 and stored in an APF-authorized library.
 * - Add module name to AUTHPGM and AUTHTSF in SYS1.PARMLIB(IKJTSO00).
 * - Activate updated IKJTSO00 (restart TSO) before running.
 */
#include "tsoeftr.h"
#include "tsowrt.h"

#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>
#ifdef __IBMC__
#include <builtins.h>
#endif

#pragma linkage(tsoeftr_call, OS)
#pragma linkage(tsowrt_call, OS)
#pragma map(tsowrt_call, "TSOWRT")

int main(void)
{
  int rc = 0;
  unsigned char *workbuf = NULL;

  puts("LUZ00026 TSOAUTH start");
  {
    /* Force rebuild: no functional change. */
    int cmd_len = 4;
    int work_len = TSOEFTR_WORKSIZE;
    int reason = 0;
    rc = 0;
    workbuf = (unsigned char *)__malloc31(TSOEFTR_WORKSIZE);
    if (workbuf == NULL) {
      puts("LUZ00028 TSOAUTH alloc failed");
      return 8;
    }
    for (size_t i = 0; i < TSOEFTR_WORKSIZE; i++) {
      workbuf[i] = 0;
    }
    tsowrt_call(workbuf, &work_len, &rc);
    if (rc != 0) {
      printf("LUZ00027 TSOAUTH failed rc=%d\n", rc);
      free(workbuf);
      return 8;
    }
    tsoeftr_call("TIME", &cmd_len, &rc, &reason, workbuf);
    printf("LUZ00029 TSOAUTH rc=%d reason=%d\n", rc, reason);
  }
  if (rc != 0) {
    printf("LUZ00027 TSOAUTH failed rc=%d\n", rc);
    free(workbuf);
    return 8;
  }
  free(workbuf);
  puts("LUZ00026 TSOAUTH ok");
  return 0;
}
