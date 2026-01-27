/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Example: initialize TSO environment, execute TIME,
 * and read command output from DDNAME SYSTSPRT.
 *
 * Platform requirements: LE required; AMODE 31; RMODE ANY; EBCDIC;
 * DDNAME SYSTSIN/SYSTSPRT allocated by JCL; MVS dataset I/O; TMP (IKJEFT01).
 *
 * Object Table:
 * | Object               | Kind | Purpose |
 * |----------------------|------|---------|
 * | lua_tso_exec_cmd     | func | Execute a TSO command via IKJEFTSR |
 * | lua_tso_print_dd     | func | Print DDNAME contents with LUZ prefix |
 * | main                 | func | Orchestrate TIME example |
 */

#pragma linkage(IKJTSOEV, OS)
#pragma linkage(IKJEFTSR, OS)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern void IKJTSOEV(int *rsv, int *rc, int *rsn, int *ec, void **cppl);
extern int IKJEFTSR(int *flags, char *cmd, int *len, int *rc, int *rsn, int *abend);

/* Change: keep the example pure C (no ASM, no REXX, no USS helpers). */
/* Problem: dynamic allocation via helper code violates project constraints. */
/* Expected effect: program relies on JCL-allocated DDNAMEs only. */
/* Impact: SYSTSPRT must be allocated to a dataset by JCL before RUN. */
static const char LUA_TSO_OUT_DD[] = "SYSTSPRT";
static const char LUA_TSO_CMD[] = "TIME";

/**
 * @brief Execute a TSO command through IKJEFTSR.
 * @param cmd Command text to execute.
 * @param cmd_rc Output: command return code.
 * @param cmd_rsn Output: command reason code.
 * @param cmd_abend Output: command abend code.
 * @return IKJEFTSR service facility RC (0 on success).
 */
static int lua_tso_exec_cmd(const char *cmd, int *cmd_rc, int *cmd_rsn, int *cmd_abend)
{
  int flags = 0x00010001;
  int len = (int)strlen(cmd);

  *cmd_rc = -1;
  *cmd_rsn = -1;
  *cmd_abend = -1;

  return IKJEFTSR(&flags, (char *)cmd, &len, cmd_rc, cmd_rsn, cmd_abend);
}

/**
 * @brief Print DDNAME contents to stdout with LUZ prefix per line.
 * @param ddname DDNAME to open (e.g., SYSTSPRT).
 * @return 0 on success, nonzero on failure (LUZ30105).
 */
static int lua_tso_print_dd(const char *ddname)
{
  FILE *fp = NULL;
  char line[256];
  char path[32];

  snprintf(path, sizeof(path), "//dd:%s", ddname);
  fp = fopen(path, "r");
  if (fp == NULL) {
    fprintf(stderr, "LUZ30105 fopen output dd=%s failed\n", ddname);
    return 8;
  }

  while (fgets(line, (int)sizeof(line), fp) != NULL) {
    size_t len = strlen(line);
    if (len > 0 && line[len - 1] == '\n') {
      printf("LUZ30110 %s", line);
    } else {
      printf("LUZ30110 %s\n", line);
    }
  }

  fclose(fp);
  return 0;
}

/**
 * @brief Run the TIME command via IKJEFTSR and print captured output.
 * @return 0 on success, nonzero on failure (LUZ30103/LUZ30104/LUZ30105).
 */
int main(void)
{
  int rc = 0;
  int rsn = 0;
  int ec = 0;
  int svc_rc = 0;
  int cmd_rc = 0;
  int cmd_rsn = 0;
  int cmd_abend = 0;
  void *cppl = NULL;

  /* IBM refs: src/tso_c_example.c.md (IKJTSOEV env init, return codes). */
  IKJTSOEV(&(int){0}, &rc, &rsn, &ec, &cppl);
  /*
   * Change: accept IKJTSOEV rc=24 when running under TMP.
   * Problem: TMP already initializes TSO/E; IKJTSOEV returns rc=24.
   * Expected effect: treat rc=24 as non-fatal and continue.
   * Impact: example runs under IKJEFT01 without spurious failure.
   */
  if (rc != 0 && rc != 8 && rc != 24) {
    fprintf(stderr, "LUZ30103 IKJTSOEV rc=%d rsn=%d ec=%d\n", rc, rsn, ec);
    return 12;
  }
  (void)cppl;

  /* IBM refs: src/tso_c_example.c.md (IKJEFTSR parameter list). */
  svc_rc = lua_tso_exec_cmd(LUA_TSO_CMD, &cmd_rc, &cmd_rsn, &cmd_abend);
  if (svc_rc != 0) {
    fprintf(stderr,
            "LUZ30104 IKJEFTSR svc_rc=%d cmd_rc=%d rsn=%d abend=%d\n",
            svc_rc, cmd_rc, cmd_rsn, cmd_abend);
    return 12;
  }

  /* Read output from SYSTSPRT DDNAME allocated in JCL. */
  if (lua_tso_print_dd(LUA_TSO_OUT_DD) != 0) {
    return 12;
  }

  return 0;
}
