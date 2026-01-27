/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Test helper to validate DAIR alloc/free wrappers via clean C flow.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | tso_env_init | function | Initialize TSO environment and return CPPL |
 * | tso_exec_cmd | function | Execute a TSO command via IKJEFTSR |
 * | read_dd_lines | function | Read DD output and emit LUZ-prefixed lines |
 * | make_ddname | function | Generate an 8-char DDNAME |
 * | main | function | Drive TSODALC/TSODFRE + IKJEFTSR test |
 *
 * Platform Requirements:
 * - LE: required (C runtime).
 * - AMODE: 31-bit.
 * - EBCDIC: DDNAME/command strings are EBCDIC.
 * - DDNAME I/O: SYSTSPRT is redirected by TSODALC.
 */
#include "tso_dair_asm.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdarg.h>

static FILE *g_log_fp = NULL;

/**
 * @brief Open SYSOUT stream for log output.
 *
 * @return 0 on success, or 8 on failure.
 */
/* Change note: write diagnostics to TSOAFLOG while SYSTSPRT is redirected.
 * Problem: logging to SYSTSPRT while reading the redirected DD loops output.
 * Expected effect: avoid infinite growth of the capture DD during tests.
 * Impact: TSOAF diagnostics appear in TSOAFLOG, not in the capture DD.
 */
static int tsoaf_log_open(void)
{
  if (g_log_fp != NULL)
    return 0;
  g_log_fp = fopen("DD:TSOAFLOG", "a");
  if (g_log_fp == NULL)
    return 8;
  setvbuf(g_log_fp, NULL, _IONBF, 0);
  return 0;
}

/**
 * @brief Emit a formatted log line to SYSOUT (not SYSTSPRT).
 *
 * @param fmt printf-style format string.
 */
static void tsoaf_log(const char *fmt, ...)
{
  va_list args;

  if (g_log_fp == NULL)
    tsoaf_log_open();
  va_start(args, fmt);
  vfprintf(g_log_fp, fmt, args);
  va_end(args);
}

#pragma linkage(IKJTSOEV, OS)
extern void IKJTSOEV(int *rsv, int *rc, int *rsn, int *ec, void **cppl);
#pragma linkage(IKJEFTSR, OS)
extern int IKJEFTSR(int *flags, char *cmd, int *len, int *rc, int *rsn,
                    int *abend);

/**
 * @brief Initialize TSO environment and return CPPL address.
 *
 * @param out_cppl Output CPPL pointer (31-bit).
 * @param out_rc Output IKJTSOEV RC.
 * @param out_rsn Output IKJTSOEV reason code.
 * @param out_abend Output IKJTSOEV abend code.
 * @return 0 on success, or 8 on failure.
 */
static int tso_env_init(void **out_cppl, int *out_rc, int *out_rsn,
                        int *out_abend)
{
  int parm1 = 0;
  int rc = 0;
  int rsn = 0;
  int abend = 0;
  void *cppl = NULL;

  if (out_cppl == NULL || out_rc == NULL || out_rsn == NULL ||
      out_abend == NULL)
    return 8;

  IKJTSOEV(&parm1, &rc, &rsn, &abend, &cppl);
  *out_cppl = cppl;
  *out_rc = rc;
  *out_rsn = rsn;
  *out_abend = abend;

  /* Ref: src/tso_c_alloc_free.c.md#ikjtsoev-return-codes */
  if (rc == 0 || rc == 8 || rc == 24)
    return cppl != NULL ? 0 : 8;
  return 8;
}

/**
 * @brief Execute a TSO command through IKJEFTSR.
 *
 * @param cmd Command string (EBCDIC).
 * @param out_rc Output TSO command RC.
 * @param out_rsn Output IKJEFTSR reason code.
 * @param out_abend Output IKJEFTSR abend code.
 * @return 0 when IKJEFTSR returns success, or 8 on failure.
 */
static int tso_exec_cmd(const char *cmd, int *out_rc, int *out_rsn,
                        int *out_abend)
{
  /* Change note: run IKJEFTSR in authorized/isolated mode (byte2=0).
   * Problem: IKJEFTSI is rejected in authorized PGM mode (RC=20/ERR=21).
   * Expected effect: IKJEFTSR runs without service-facility token.
   * Impact: command executes in isolated authorized environment.
   */
  int flags = 0x00000001;
  int len = 0;
  int svc_rc = 0;
  int cmd_rc = 0;
  int cmd_rsn = 0;
  int cmd_abend = 0;

  if (cmd == NULL || out_rc == NULL || out_rsn == NULL ||
      out_abend == NULL)
    return 8;

  len = (int)strlen(cmd);
  /* Ref: src/tso_c_alloc_free.c.md#ikjeftsr-parameter-list */
  svc_rc = IKJEFTSR(&flags, (char *)cmd, &len, &cmd_rc, &cmd_rsn, &cmd_abend);
  *out_rc = cmd_rc;
  *out_rsn = cmd_rsn;
  *out_abend = cmd_abend;

  if (svc_rc != 0)
    return 8;
  return 0;
}

/**
 * @brief Read DD output and emit LUZ-prefixed lines.
 *
 * @param ddname DDNAME to read (EBCDIC, 1-8 chars).
 * @return 0 on success, or 8 on failure.
 */
static int read_dd_lines(const char *ddname)
{
  char path[32];
  FILE *fp = NULL;
  char buf[2048];

  if (ddname == NULL || ddname[0] == '\0')
    return 8;
  if (snprintf(path, sizeof(path), "DD:%s", ddname) <= 0)
    return 8;
  fp = fopen(path, "rb,type=record");
  if (fp == NULL)
    fp = fopen(path, "rb");
  if (fp == NULL)
    return 8;

  while (fgets(buf, sizeof(buf), fp) != NULL) {
    size_t len = strcspn(buf, "\r\n");
    tsoaf_log("LUZ00035 TSOAF %.*s\n", (int)len, buf);
  }

  fclose(fp);
  return 0;
}

/**
 * @brief Generate a deterministic 8-char DDNAME.
 *
 * @param out_ddname Output buffer (must hold 9 bytes).
 * @param seq Sequence number (0-99).
 */
static void make_ddname(char *out_ddname, int seq)
{
  if (out_ddname == NULL)
    return;
  snprintf(out_ddname, 9, "TSAF%04d", seq % 10000);
  out_ddname[8] = '\0';
}

/**
 * @brief Drive TSODALC/TSODFRE + IKJEFTSR to validate alloc/free.
 *
 * @return 0 on success, or 8 on failure.
 */
int main(void)
{
  void *cppl = NULL;
  int rc = 0;
  int rsn = 0;
  int abend = 0;
  int dair_rc = 0;
  int cat_rc = 0;
  int cmd_rc = 0;
  int cmd_rsn = 0;
  int cmd_abend = 0;
  char ddname[9];
  void *work = NULL;

  if (tsoaf_log_open() != 0) {
    puts("LUZ00038 TSOAF log DD open failed");
    return 8;
  }
  tsoaf_log("LUZ00030 TSOAF start\n");

  if (tso_env_init(&cppl, &rc, &rsn, &abend) != 0) {
    tsoaf_log("LUZ00031 TSOAF IKJTSOEV rc=%d rsn=%d abend=%d cppl=%p\n",
              rc, rsn, abend, cppl);
    tsoaf_log("LUZ00037 TSOAF failed\n");
    return 8;
  }
  tsoaf_log("LUZ00031 TSOAF IKJTSOEV rc=%d rsn=%d abend=%d cppl=%p\n",
            rc, rsn, abend, cppl);

  work = __malloc31(TSODAIR_WORKSIZE);
  if (work == NULL) {
    tsoaf_log("LUZ00037 TSOAF failed\n");
    return 8;
  }
  memset(work, 0, TSODAIR_WORKSIZE);

  make_ddname(ddname, 1);
  /* Change note: exercise TSODALC/TSODFRE to validate DAIR wrappers.
   * Problem: alloc/free path needs direct debug outside Lua runtime.
   * Expected effect: TSODALC redirects SYSTSPRT to private DDNAME.
   * Impact: IKJEFTSR output is captured via the temporary DD.
   */
  if (tsodalc_call(cppl, ddname, &dair_rc, &cat_rc, work) != 0) {
    tsoaf_log("LUZ00032 TSOAF tsodalc dd=%s dair_rc=%d cat_rc=%d\n",
              ddname, dair_rc, cat_rc);
    tsoaf_log("LUZ00037 TSOAF failed\n");
    free(work);
    return 8;
  }
  tsoaf_log("LUZ00032 TSOAF tsodalc dd=%s dair_rc=%d cat_rc=%d\n",
            ddname, dair_rc, cat_rc);

  /* Change note: invoke IKJEFTSR in authorized/isolated mode.
   * Problem: IKJEFTSI RC=20 ERR=21 when running authorized in PGM mode.
   * Expected effect: IKJEFTSR runs without service-facility token.
   * Impact: no IKJEFTSI/IKJEFTST lifecycle in this test.
   */
  if (tso_exec_cmd("TIME", &cmd_rc, &cmd_rsn, &cmd_abend) != 0) {
    tsoaf_log("LUZ00033 TSOAF IKJEFTSR svc_rc=8 cmd_rc=%d rsn=%d abend=%d\n",
              cmd_rc, cmd_rsn, cmd_abend);
  } else {
    tsoaf_log("LUZ00033 TSOAF IKJEFTSR svc_rc=0 cmd_rc=%d rsn=%d abend=%d\n",
              cmd_rc, cmd_rsn, cmd_abend);
  }

  if (read_dd_lines(ddname) != 0)
    tsoaf_log("LUZ00034 TSOAF read dd=%s failed\n", ddname);

  if (tsodfre_call(cppl, ddname, &dair_rc, &cat_rc, work) != 0) {
    tsoaf_log("LUZ00036 TSOAF tsodfre dd=%s dair_rc=%d cat_rc=%d\n",
              ddname, dair_rc, cat_rc);
    tsoaf_log("LUZ00037 TSOAF failed\n");
    free(work);
    return 8;
  }
  tsoaf_log("LUZ00036 TSOAF tsodfre dd=%s dair_rc=%d cat_rc=%d\n",
            ddname, dair_rc, cat_rc);

  free(work);
  return 0;
}
