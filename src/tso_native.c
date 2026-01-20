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
 * | tso_native_alloc | function | Dynamic allocation via DAIR |
 * | tso_native_free | function | Dynamic deallocation via DAIR |
 * | tso_native_msg | function | Emit a TSO message |
 * | g_env_state | variable | Cache TSO environment probe state |
 * | g_env_rc | variable | Last IKJTSOEV return code |
 * | g_env_reason | variable | Last IKJTSOEV reason code |
 * | g_env_abend | variable | Last IKJTSOEV abend code |
 * | g_env_cppl | variable | Cached CPPL pointer from IKJTSOEV |
 *
 * User Actions:
 * - Run under TMP (IKJEFT01) or ensure TSO/E environment is established.
 * - Check SYSOUT/SYSTSPRT allocation when output is expected.
 */
#include "tso_native.h"
#include "errors.h"
#include "tso_ikjeftsr.h"

#include <string.h>
#include <stdlib.h>
#include <stdint.h>

typedef void * __ptr32 ptr32;

#pragma linkage(fetch, OS)
extern void (*fetch(const char *name))();

typedef void (*ikjtsoev_fn)(int *, int *, int *, int *, void **);
typedef void (*ikjeftsi_fn)(ptr32 *);
typedef void (*ikjeftsr_fn)(ptr32 *);
static int g_env_state = 0; /* 0=unknown, 1=ready, -1=failed */
static int g_env_rc = 0;
static int g_env_reason = 0;
static int g_env_abend = 0;
static void *g_env_cppl = NULL;

static ptr32 tso_last_ptr(ptr32 p)
{
  uintptr_t v = (uintptr_t)p;
  v |= (uintptr_t)0x80000000u;
  return (ptr32)v;
}

int tso_native_env_init(void)
{
  ikjtsoev_fn ikjtsoev;
  int parm1 = 0;

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

int tso_native_cmd(const char *cmd, const char *outdd)
{
  ikjeftsi_fn ikjeftsi;
  ikjeftsr_fn ikjeftsr;
  tso_eftsr_flags flags;
  int cmd_len = 0;
  int rc = -1;
  int reason = 0;
  int abend = 0;
  size_t plist_size = 0;
  size_t block_size = 0;
  ptr32 *parms = NULL;
  struct tso_call_block {
    tso_eftsr_flags flags;
    int cmd_len;
    int rc;
    int reason;
    int abend;
    int pgm_parm;
    uint32_t cppl[4];
    unsigned char token[16];
    char cmd[1];
  } *block = NULL;
  struct tso_si_block {
    int ectparm;
    int reserved;
    unsigned char token[16];
    int error;
    int abend;
    int reason;
  } *sib = NULL;
  ptr32 *parmsi = NULL;


  (void)outdd;
  if (cmd == NULL || cmd[0] == '\0')
    return LUZ_E_TSO_CMD;
  if (tso_native_env_init() != 0)
    return LUZ_E_TSO_CMD;

  ikjeftsi = (ikjeftsi_fn)fetch("IKJTSFI");
  if (ikjeftsi == NULL)
    ikjeftsi = (ikjeftsi_fn)fetch("IKJEFTSI");
  ikjeftsr = (ikjeftsr_fn)fetch("IKJEFTSR");
  if (ikjeftsr == NULL || ikjeftsi == NULL)
    return LUZ_E_TSO_CMD;

  cmd_len = (int)strlen(cmd);
  memset(&flags, 0, sizeof(flags));
  flags.b2 = TSO_EFTSR_AUTH;
  flags.b3 = TSO_EFTSR_NODUMP;
  flags.b4 = TSO_EFTSR_CMD;

  plist_size = 9 * sizeof(ptr32);
  block_size = sizeof(*block) + (size_t)cmd_len;
  parms = (ptr32 *)__malloc31(plist_size);
  block = (struct tso_call_block *)__malloc31(block_size);
  parmsi = (ptr32 *)__malloc31(6 * sizeof(ptr32));
  sib = (struct tso_si_block *)__malloc31(sizeof(*sib));
  if (parms == NULL || block == NULL || parmsi == NULL || sib == NULL) {
    if (parms)
      free(parms);
    if (block)
      free(block);
    if (parmsi)
      free(parmsi);
    if (sib)
      free(sib);
    return LUZ_E_TSO_CMD;
  }

  memset(block, 0, block_size);
  block->flags = flags;
  block->cmd_len = cmd_len;
  memcpy(block->cmd, cmd, (size_t)cmd_len);
  block->cmd[cmd_len] = '\0';
  memset(sib, 0, sizeof(*sib));

  parmsi[0] = (ptr32)&sib->ectparm;
  parmsi[1] = (ptr32)&sib->reserved;
  parmsi[2] = (ptr32)sib->token;
  parmsi[3] = (ptr32)&sib->error;
  parmsi[4] = (ptr32)&sib->abend;
  parmsi[5] = tso_last_ptr((ptr32)&sib->reason);
  ikjeftsi(parmsi);
  if (sib->error != 0 || sib->abend != 0) {
    free(parms);
    free(block);
    free(parmsi);
    free(sib);
    return LUZ_E_TSO_CMD;
  }
  memcpy(block->token, sib->token, sizeof(block->token));

  parms[0] = (ptr32)&block->flags;
  parms[1] = (ptr32)block->cmd;
  parms[2] = (ptr32)&block->cmd_len;
  parms[3] = (ptr32)&block->rc;
  parms[4] = (ptr32)&block->reason;
  parms[5] = (ptr32)&block->abend;
  parms[6] = (ptr32)&block->pgm_parm;
  parms[7] = (ptr32)block->cppl;
  parms[8] = tso_last_ptr((ptr32)block->token);

  ikjeftsr(parms);
  rc = block->rc;
  if (rc != 0) {
    free(parms);
    free(block);
    free(parmsi);
    free(sib);
    return LUZ_E_TSO_CMD;
  }
  free(parms);
  free(block);
  free(parmsi);
  free(sib);
  return 0;
}

int tso_native_alloc(const char *spec)
{
  (void)spec;
  return LUZ_E_TSO_ALLOC;
}

int tso_native_free(const char *spec)
{
  (void)spec;
  return LUZ_E_TSO_FREE;
}

int tso_native_msg(const char *text, int level)
{
  (void)text;
  (void)level;
  return LUZ_E_TSO_MSG;
}
