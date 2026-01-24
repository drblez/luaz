/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Native TSO backend stubs (no REXX).
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | tso_native_env_init | function | Validate TSO environment for native services |
 * | tso_native_cmd | function | Execute a TSO command via native services |
 * | tso_native_cmd_cp | function | Execute a TSO command via TSOAUTH command processor |
 * | tso_native_cmd_cleanup | function | Release internal DD allocations after command |
 * | tso_native_set_cppl | function | Set CPPL pointer from TSO command processor |
 * | tso_native_alloc | function | Dynamic allocation via DAIR |
 * | tso_native_free | function | Dynamic deallocation via DAIR |
 * | tso_native_msg | function | Emit a TSO message |
 * | g_env_state | variable | Cache TSO environment probe state |
 * | g_env_rc | variable | Last IKJTSOEV return code |
 * | g_env_reason | variable | Last IKJTSOEV reason code |
 * | g_env_abend | variable | Last IKJTSOEV abend code |
 * | g_env_cppl | variable | Cached CPPL pointer from IKJTSOEV |
 * | g_dd_seq | variable | Sequence for internal DDNAME generation |
 *
 * User Actions:
 * - Run under TMP (IKJEFT01) or ensure TSO/E environment is established.
 * - Output capture uses an internal DD via DAIR; no user DDNAME is required.
 */
#include "TSONATV"
#include "ERRORS"
#include "TSOCMDA"
#include "TSODASM"

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#pragma linkage(fetch, OS)
/* LE service resolver for dynamic entry points (e.g., IKJTSOEV). */
extern void (*fetch(const char *name))();

/* IKJTSOEV function signature for environment probing. */
typedef void (*ikjtsoev_fn)(int *, int *, int *, int *, void **);
static int g_env_state = 0; /* 0=unknown, 1=ready, -1=failed */
static int g_env_rc = 0;    /* Last IKJTSOEV return code. */
static int g_env_reason = 0; /* Last IKJTSOEV reason code. */
static int g_env_abend = 0; /* Last IKJTSOEV abend code. */
static void *g_env_cppl = NULL; /* Cached CPPL pointer. */
static unsigned int g_dd_seq = 0; /* Internal DDNAME sequence. */

/* Command execution state captured from TSOCMD output slots. */
typedef struct tso_cmd_state_t {
  int reason;
  int abend;
  int dair_rc;
  int cat_rc;
} tso_cmd_state_t;

/**
 * @brief Emit a diagnostic message for native TSO operations.
 *
 * @param msg NUL-terminated message string with LUZ prefix, or NULL to skip.
 */
static void tso_native_diag(const char *msg)
{
  if (msg == NULL)
    return;
  printf("%s\n", msg);
  fflush(NULL);
}

#pragma linkage(tso_native_set_cppl, OS)
#pragma export(tso_native_set_cppl)
#pragma map(tso_native_set_cppl, "TSONCPPL")
/**
 * @brief Cache the CPPL pointer provided by a TSO command processor.
 *
 * @param cppl CPPL pointer supplied by the command processor entry.
 */
void tso_native_set_cppl(void *cppl)
{
  if (cppl == NULL)
    return;
  g_env_cppl = cppl;
  g_env_state = 1;
  g_env_rc = 0;
  g_env_reason = 0;
  g_env_abend = 0;
}

/**
 * @brief Generate a unique internal DDNAME for output capture.
 *
 * @param outdd Output buffer to receive the DDNAME (EBCDIC, 8 chars + NUL).
 * @param outdd_len Size of the output buffer in bytes.
 * @return 1 on success, 0 on failure.
 */
static int tso_gen_ddname(char *outdd, size_t outdd_len)
{
  unsigned int next;

  if (outdd == NULL || outdd_len < 9)
    return 0;
  next = (g_dd_seq + 1u) & 0x00FFFFFFu;
  if (next == 0u)
    next = 1u;
  g_dd_seq = next;
  if (snprintf(outdd, outdd_len, "LZ%06X", g_dd_seq) <= 0)
    return 0;
  return 1;
}

/**
 * @brief Validate or discover the LE/TSO environment for native services.
 *
 * @return 0 on success, LUZ_E_TSO_CMD on failure.
 */
int tso_native_env_init(void)
{
  ikjtsoev_fn ikjtsoev;
  int parm1 = 0;

  if (g_env_cppl != NULL) {
    g_env_state = 1;
    return 0;
  }
  if (g_env_state == 1)
    return 0;
  if (g_env_state == -1)
    return LUZ_E_TSO_CMD;

  ikjtsoev = (ikjtsoev_fn)fetch("IKJTSOEV");
  if (ikjtsoev == NULL) {
    g_env_state = -1;
    g_env_rc = -1;
    return LUZ_E_TSO_CMD;
  }
  ikjtsoev(&parm1, &g_env_rc, &g_env_reason, &g_env_abend, &g_env_cppl);
  if (g_env_rc == 0) {
    g_env_state = 1;
    return 0;
  }
  g_env_state = -1;
  return LUZ_E_TSO_CMD;
}

/**
 * @brief Execute a TSO command via IKJEFTSR using the ASM TSOCMD path.
 *
 * @param cmd NUL-terminated command string (EBCDIC).
 * @param outdd Output buffer for the generated DDNAME (8 chars + NUL).
 * @param outdd_len Size of outdd in bytes.
 * @param reason Optional pointer to receive IKJEFTSR reason code.
 * @param abend Optional pointer to receive IKJEFTSR abend code.
 * @param dair_rc Optional pointer to receive DAIR return code.
 * @param cat_rc Optional pointer to receive catalog return code.
 * @return 0 on success, or LUZ_E_TSO_CMD on failure.
 */
int tso_native_cmd(const char *cmd, char *outdd, size_t outdd_len,
                   int *reason, int *abend, int *dair_rc, int *cat_rc)
{
  int cmd_len = 0;
  int rc = -1;
  int local_reason = 0;
  int local_abend = 0;
  int local_dair_rc = 0;
  int local_cat_rc = 0;
  void *work = NULL;
  tso_cmd_parms_t *parms = NULL;
  tso_cmd_state_t *state = NULL;
  char *cmd_31 = NULL;
  char *outdd_31 = NULL;

  if (cmd == NULL || cmd[0] == '\0')
    return LUZ_E_TSO_CMD;
  if (outdd != NULL && outdd_len > 0)
    outdd[0] = '\0';
  if (reason)
    *reason = 0;
  if (abend)
    *abend = 0;
  if (dair_rc)
    *dair_rc = 0;
  if (cat_rc)
    *cat_rc = 0;
  if (tso_native_env_init() != 0)
  {
    tso_native_diag("LUZ30061 tso_native_env_init failed");
    return LUZ_E_TSO_CMD;
  }
  if (g_env_cppl == NULL) {
    tso_native_diag("LUZ30062 tso_native CPPL unavailable");
    return LUZ_E_TSO_CMD;
  }
  if (!tso_gen_ddname(outdd, outdd_len)) {
    tso_native_diag("LUZ30063 tso_native DDNAME allocation failed");
    return LUZ_E_TSO_CMD;
  }

  cmd_len = (int)strlen(cmd);
  work = __malloc31(TSOCMD_WORKSIZE);
  if (work == NULL) {
    tso_native_diag("LUZ30064 tso_native work buffer allocation failed");
    return LUZ_E_TSO_CMD;
  }
  memset(work, 0, TSOCMD_WORKSIZE);
  parms = (tso_cmd_parms_t *)__malloc31(sizeof(*parms));
  state = (tso_cmd_state_t *)__malloc31(sizeof(*state));
  cmd_31 = (char *)__malloc31((size_t)cmd_len + 1u);
  outdd_31 = (char *)__malloc31(9u);
  if (parms == NULL || state == NULL || cmd_31 == NULL || outdd_31 == NULL) {
    free(work);
    free(parms);
    free(state);
    free(cmd_31);
    free(outdd_31);
    tso_native_diag("LUZ30064 tso_native work buffer allocation failed");
    return LUZ_E_TSO_CMD;
  }

  memset(parms, 0, sizeof(*parms));
  memset(state, 0, sizeof(*state));
  memcpy(cmd_31, cmd, (size_t)cmd_len);
  cmd_31[cmd_len] = '\0';
  memcpy(outdd_31, outdd, 8u);
  outdd_31[8] = '\0';

  parms->cppl = (void * __ptr32)g_env_cppl;
  parms->cmd = (char * __ptr32)cmd_31;
  parms->cmd_len = cmd_len;
  parms->outdd = (char * __ptr32)outdd_31;
  parms->reason = (int32_t * __ptr32)&state->reason;
  parms->abend = (int32_t * __ptr32)&state->abend;
  parms->dair_rc = (int32_t * __ptr32)&state->dair_rc;
  parms->cat_rc = (int32_t * __ptr32)&state->cat_rc;
  parms->work = (void * __ptr32)work;

  rc = tsocmd_call(parms);
  local_reason = state->reason;
  local_abend = state->abend;
  local_dair_rc = state->dair_rc;
  local_cat_rc = state->cat_rc;

  free(cmd_31);
  free(outdd_31);
  free(state);
  free(parms);
  free(work);
  if (rc < 0) {
    if (outdd != NULL && outdd_len > 0)
      outdd[0] = '\0';
    if (dair_rc)
      *dair_rc = local_dair_rc;
    if (cat_rc)
      *cat_rc = local_cat_rc;
    printf("LUZ30065 tso_native TSOCMD failed dair_rc=%d cat_rc=%d\n",
           local_dair_rc, local_cat_rc);
    printf("LUZ30067 tso_native TSOCMD rc=%d\n", rc);
    fflush(NULL);
    return LUZ_E_TSO_CMD;
  }

  if (reason)
    *reason = local_reason;
  if (abend)
    *abend = local_abend;
  if (dair_rc)
    *dair_rc = local_dair_rc;
  if (cat_rc)
    *cat_rc = local_cat_rc;

  return rc;
}

/**
 * @brief Execute a TSO command through the TSOAUTH command processor.
 *
 * @param cmd NUL-terminated command string (EBCDIC).
 * @param outdd Output buffer for the generated DDNAME (8 chars + NUL).
 * @param outdd_len Size of outdd in bytes.
 * @param reason Optional pointer to receive IKJEFTSR reason code.
 * @param abend Optional pointer to receive IKJEFTSR abend code.
 * @param dair_rc Optional pointer to receive DAIR return code.
 * @param cat_rc Optional pointer to receive catalog return code.
 * @return 0 on success, or LUZ_E_TSO_CMD on failure.
 */
int tso_native_cmd_cp(const char *cmd, char *outdd, size_t outdd_len,
                      int *reason, int *abend, int *dair_rc, int *cat_rc)
{
  const char *prefix = "TSOAUTH ";
  size_t cmd_len = 0;
  size_t prefix_len = 0;
  size_t total_len = 0;
  char *full = NULL;
  int rc = LUZ_E_TSO_CMD;

  if (cmd == NULL || cmd[0] == '\0')
    return LUZ_E_TSO_CMD;
  cmd_len = strlen(cmd);
  prefix_len = strlen(prefix);
  total_len = prefix_len + cmd_len + 1;
  full = (char *)malloc(total_len);
  if (full == NULL)
    return LUZ_E_TSO_CMD;
  memcpy(full, prefix, prefix_len);
  memcpy(full + prefix_len, cmd, cmd_len);
  full[total_len - 1] = '\0';
  rc = tso_native_cmd(full, outdd, outdd_len, reason, abend, dair_rc, cat_rc);
  free(full);
  return rc;
}

/**
 * @brief Free the internal DDNAME allocation after reading command output.
 *
 * @param outdd NUL-terminated DDNAME used for output capture.
 * @return 0 on success, or LUZ_E_TSO_CMD on failure.
 */
int tso_native_cmd_cleanup(const char *outdd)
{
  int local_dair_rc = 0;
  int local_cat_rc = 0;
  void *work = NULL;
  char *outdd_31 = NULL;

  if (outdd == NULL || outdd[0] == '\0')
    return LUZ_E_TSO_CMD;
  if (tso_native_env_init() != 0)
    return LUZ_E_TSO_CMD;
  if (g_env_cppl == NULL)
    return LUZ_E_TSO_CMD;
  work = __malloc31(TSODAIR_WORKSIZE);
  if (work == NULL)
    return LUZ_E_TSO_CMD;
  memset(work, 0, TSODAIR_WORKSIZE);
  outdd_31 = (char *)__malloc31(9u);
  if (outdd_31 == NULL) {
    free(work);
    free(outdd_31);
    return LUZ_E_TSO_CMD;
  }
  memcpy(outdd_31, outdd, 8u);
  outdd_31[8] = '\0';

  if (tsodfre_call(g_env_cppl, outdd_31, &local_dair_rc, &local_cat_rc, work) !=
      0) {
    free(outdd_31);
    free(work);
    return LUZ_E_TSO_CMD;
  }
  free(outdd_31);
  free(work);
  return 0;
}

/**
 * @brief Placeholder for DAIR allocation wrapper (not implemented).
 *
 * @param spec Allocation specification string (unused).
 * @return LUZ_E_TSO_ALLOC to indicate unimplemented function.
 */
int tso_native_alloc(const char *spec)
{
  (void)spec;
  return LUZ_E_TSO_ALLOC;
}

/**
 * @brief Placeholder for DAIR deallocation wrapper (not implemented).
 *
 * @param spec Allocation specification string (unused).
 * @return LUZ_E_TSO_FREE to indicate unimplemented function.
 */
int tso_native_free(const char *spec)
{
  (void)spec;
  return LUZ_E_TSO_FREE;
}

/**
 * @brief Placeholder for native TSO message emission (not implemented).
 *
 * @param text Message text (unused).
 * @param level Message severity/level (unused).
 * @return LUZ_E_TSO_MSG to indicate unimplemented function.
 */
int tso_native_msg(const char *text, int level)
{
  (void)text;
  (void)level;
  return LUZ_E_TSO_MSG;
}
