/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO TSO host API stubs.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | read_dd_to_lines | function | Read DDNAME output into Lua table |
 * | tso_alloc_outdd | function | Allocate temporary OUTDD via DAIR |
 * | tso_free_outdd | function | Free temporary OUTDD allocation |
 * | tso_stack_outdd | function | Route output to OUTDD via STACK |
 * | tso_stack_close | function | Close STACK dataset DCBs |
 * | tso_stack_delete | function | Delete STACK top element |
 * | tso_ikjeftsr_call | function | Invoke IKJEFTSR with optional CPPL |
 * | tso_call_rexx | function | Invoke LUTSO REXX exec via IRXEXEC |
 * | l_tso_cmd | function | Lua wrapper for tso.cmd |
 * | l_tso_alloc | function | Lua wrapper for tso.alloc |
 * | l_tso_free | function | Lua wrapper for tso.free |
 * | l_tso_msg | function | Lua wrapper for tso.msg |
 * | l_tso_exit | function | Lua wrapper for tso.exit |
 * | lua_tso_cmd | function | Execute a TSO command |
 * | lua_tso_cmd_nocap | function | Execute a TSO command via IKJEFTSR (no capture) |
 * | lua_tso_cmd_capture | function | Execute a TSO command via REXX OUTTRAP capture |
 * | lua_tso_set_cppl_cmd | function | Cache CPPL for IKJEFTSR command calls |
 * | lua_tso_alloc | function | Allocate a dataset |
 * | lua_tso_free | function | Free a dataset allocation |
 * | lua_tso_msg | function | Emit a TSO message |
 * | lua_tso_exit | function | Exit with RC |
 * | luaopen_tso | function | Lua module entrypoint |
 */
#include "TSO"
#include "ERRORS"
#include "TSONATV"
#include "tso_dair_asm.h"

#include "LUA"
#include "LAUXLIB"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>

/* IKJTSOEV function signature for environment probing. */
typedef void (*ikjtsoev_fn)(int *, int *, int *, int *, void **);
/* IKJEFTSR OS linkage prototypes for 6- and 8-parameter calls.
 * Change note: mirror the explicit extern style used in tso_c_example.c.
 * Problem: function-pointer typedefs with pragma linkage emit CCN3708.
 * Expected effect: cleaner prototypes and OS-linkage plist generation.
 * Impact: IKJEFTSR param7/8 calls remain in pure C, no ASM required.
 * Ref: src/tso.c.md#os-linkage-plist
 */
#pragma linkage(IKJEFTSR, OS)
extern int IKJEFTSR(int *flags, char *cmd, int *len, int *rc, int *rsn,
                    int *abend);
#pragma linkage(IKJEFTSR8, OS)
#pragma map(IKJEFTSR8, "IKJEFTSR")
extern int IKJEFTSR8(int *flags, char *cmd, int *len, int *rc, int *rsn,
                     int *abend, int *parm7, void *cppl);
/* TSOSTK OS linkage prototype for STACK output routing. */
#pragma linkage(TSOSTK, OS)
extern int TSOSTK(void *cppl, const char *outdd, int op);
/* Forward declaration for IRXEXEC parameter block. */
typedef struct IRXEXEC_type IRXEXEC_type;
#pragma linkage(fetch, OS)
/* LE service resolver for dynamic entry points (IKJTSOEV/IRXEXEC). */
extern void (*fetch(const char *name))();
typedef int (*irxexec_fn)();
static int g_last_irx_rc = 0; /* Last IRXEXEC return code. */
static int g_last_rexx_rc = 0; /* Last REXX return code. */
static int g_cppl_addr = 0; /* Cached CPPL address (31-bit). */
static size_t g_systsprt_offset = 0; /* Bytes read from SYSTSPRT (per process). */
/* Change note: retain legacy OUTDD name for STACK routing helpers.
 * Problem: STACK/DAIR capture remains in the source tree for reference.
 * Expected effect: legacy helpers still share a stable DDNAME constant.
 * Impact: unused by tso.cmd until STACK capture is reinstated.
 */
static const char g_tso_outdd_name[] = "LUZOUT00";

/* STACK operation selectors for TSOSTK. */
enum {
  TSO_STK_OUTDD = 0,
  TSO_STK_CLOSE = 1,
  TSO_STK_DELETE = 2
};


/* REXX evaluation block layout for IRXEXEC. */
typedef struct EVALBLK_type {
  int EVPADD1;
  int EVSIZE;
  int EVLEN;
  int EVPADD2;
  char EVDATA[256];
} EVALBLK_type;

/* REXX exec block layout for IRXEXEC. */
typedef struct EXECBLK_type {
  char EXECBLK_ACRYN[8];
  int EXECBLK_LENGTH;
  int EXECBLK_reserved;
  char EXECBLK_MEMBER[8];
  char EXECBLK_DDNAME[8];
  char EXECBLK_SUBCOM[8];
  void *EXECBLK_DSNPTR;
  int EXECBLK_DSNLEN;
} EXECBLK_type;

/* REXX single parameter descriptor. */
typedef struct one_parameter_type {
  void *ARGSTRING_PTR;
  int ARGSTRING_LENGTH;
} one_parameter_type;

/* IRXEXEC parameter block layout (pointers to parameter areas). */
typedef struct IRXEXEC_type {
  EXECBLK_type **execblk_ptr;
  one_parameter_type **argtable_ptr;
  int *flags_ptr;
  int *instblk_ptr;
  int *cppl_ptr;
  EVALBLK_type **evalblk_ptr;
  int *workarea_ptr;
  int *userfield_ptr;
  int *envblock_ptr;
  int *rexx_rc_ptr;
} IRXEXEC_type;

/**
 * @brief Convert an IRXEXEC EVALBLK payload into an integer RC.
 *
 * @param evalblk Pointer to EVALBLK_type returned by IRXEXEC.
 * @param out_rc Output location for parsed integer RC.
 * @return 1 when RC was parsed, or 0 when parsing failed.
 */
static int evalblk_to_rc(const EVALBLK_type *evalblk, int *out_rc)
{
  int i = 0;
  int rc = 0;
  int sign = 1;

  if (evalblk == NULL || out_rc == NULL)
    return 0;
  if (evalblk->EVLEN <= 0 || evalblk->EVLEN > (int)sizeof(evalblk->EVDATA))
    return 0;
  if (evalblk->EVDATA[0] == (char)0x60) {
    sign = -1;
    i = 1;
  }
  for (; i < evalblk->EVLEN; i++) {
    unsigned char c = (unsigned char)evalblk->EVDATA[i];
    if (c < 0xF0 || c > 0xF9)
      break;
    rc = (rc * 10) + (c - 0xF0);
  }
  if ((sign == -1 && i == 1) || (sign == 1 && i == 0))
    return 0;
  *out_rc = rc * sign;
  return 1;
}

/**
 * @brief Cache a CPPL pointer value for IKJEFTSR command execution.
 *
 * @param cppl CPPL pointer supplied by LUACMD (address parameter).
 * @return None.
 */
void lua_tso_set_cppl_cmd(void *cppl)
{
  uintptr_t cppl_addr = 0;

  if (cppl == NULL)
    return;
  cppl_addr = (uintptr_t)cppl & (uintptr_t)0x7FFFFFFFu;
  if (cppl_addr == 0)
    return;
  /* Change note: cache LUACMD CPPL for IKJEFTSR optional parameter 8.
   * Problem: CPPL from LUACMD was ignored in clean C command calls.
   * Expected effect: tso.cmd can supply param7/8 when CPPL is available.
   * Impact: IKJEFTSR sees the command processor CPPL for TSO commands.
   * Ref: src/tso.c.md#ikjeftsr-param8-cppl
   */
  g_cppl_addr = (int)cppl_addr;
}

/**
 * @brief Ensure a TSO environment is active and cache CPPL address.
 *
 * @return 0 on success, or -1 on failure (g_last_irx_rc/g_last_rexx_rc set).
 */
static int tso_env_init(void)
{
  static int env_state = 0; /* 0=unknown, 1=ready, -1=failed */
  ikjtsoev_fn ikjtsoev;
  int parm1 = 0;
  int rc = 0;
  int reason = 0;
  int abend = 0;
  void *cppl = NULL;

  if (env_state == 1)
    return 0;
  if (env_state == -1)
    return -1;
  /* Change note: treat cached LUACMD CPPL as a valid TSO environment.
   * Problem: LUACMD passes CPPL but tso_env_init always re-queries IKJTSOEV.
   * Expected effect: CPPL-provided runs bypass redundant IKJTSOEV checks.
   * Impact: tso.cmd can proceed with IKJEFTSR param8 when CPPL is cached.
   * Ref: src/tso.c.md#ikjeftsr-param8-cppl
   */
  if (g_cppl_addr != 0) {
    env_state = 1;
    return 0;
  }

  ikjtsoev = (ikjtsoev_fn)fetch("IKJTSOEV");
  if (ikjtsoev == NULL) {
    env_state = -1;
    g_last_irx_rc = -2;
    g_last_rexx_rc = 0;
    return -1;
  }

  ikjtsoev(&parm1, &rc, &reason, &abend, &cppl);
  /*
   * Change: accept IKJTSOEV rc=8/24 for clean C path under TMP.
   * Problem: TMP already initializes TSO/E; IKJTSOEV returns rc=24.
   * Expected effect: allow IKJEFTSR usage without failing env init.
   * Impact: clean C tso.cmd works in batch (IKJEFT01).
   * Ref: src/tso.md#tso-clean-c
   */
  if (rc == 0 || rc == 8 || rc == 24) {
    if (cppl != NULL)
      g_cppl_addr = (int)(uintptr_t)cppl;
    env_state = 1;
    return 0;
  }

  env_state = -1;
  g_last_irx_rc = rc;
  g_last_rexx_rc = reason;
  g_cppl_addr = 0;
  return -1;
}

/**
 * @brief Invoke IKJEFTSR using a 6- or 8-parameter OS linkage plist.
 *
 * @param cmd Command string (EBCDIC).
 * @param cmd_rc Output command return code.
 * @param cmd_rsn Output reason code.
 * @param cmd_abend Output abend code.
 * @return IKJEFTSR service return code.
 */
static int tso_ikjeftsr_call(const char *cmd, int *cmd_rc, int *cmd_rsn,
                             int *cmd_abend)
{
  int flags = 0x00010001;
  int len = 0;
  int parm7_zero = 0;
  void *cppl = NULL;

  if (cmd == NULL || cmd[0] == '\0')
    return -1;
  len = (int)strlen(cmd);
  if (g_cppl_addr != 0)
    cppl = (void *)(uintptr_t)g_cppl_addr;
  if (cppl != NULL) {
    /* Change note: pass CPPL via IKJEFTSR optional parameter 8.
     * Problem: CPPL was not forwarded, limiting command execution context.
     * Expected effect: IKJEFTSR receives param7/8 with OS linkage plist.
     * Impact: tso.cmd runs with LUACMD-provided CPPL when available.
     * Ref: src/tso.c.md#ikjeftsr-param8-cppl
     */
    return IKJEFTSR8(&flags, (char *)cmd, &len, cmd_rc, cmd_rsn, cmd_abend,
                     &parm7_zero, cppl);
  }
  return IKJEFTSR(&flags, (char *)cmd, &len, cmd_rc, cmd_rsn, cmd_abend);
}

/**
 * @brief Pad a DDNAME to 8 characters with trailing spaces.
 *
 * @param outdd Output 8-character DDNAME buffer.
 * @param name Source DDNAME string (1-8 chars).
 * @return None.
 */
static void tso_ddname_pad(char outdd[8], const char *name)
{
  size_t i = 0;

  memset(outdd, ' ', 8);
  if (name == NULL)
    return;
  for (i = 0; i < 8 && name[i] != '\0'; i++) {
    outdd[i] = name[i];
  }
}

/**
 * @brief Convert an 8-byte DDNAME (EBCDIC, padded) into a C string.
 *
 * @param out_ddname Output NUL-terminated DDNAME buffer (size 9).
 * @param in_ddname Input 8-byte DDNAME (padded with spaces).
 * @return None.
 */
static void tso_ddname_unpad(char out_ddname[9], const char in_ddname[8])
{
  size_t i = 0;

  if (out_ddname == NULL)
    return;
  out_ddname[0] = '\0';
  if (in_ddname == NULL)
    return;
  for (i = 0; i < 8 && in_ddname[i] != ' '; i++) {
    out_ddname[i] = in_ddname[i];
  }
  out_ddname[i] = '\0';
}

/**
 * @brief Format an 8-byte DDNAME buffer into a 16-char hex string.
 *
 * @param out_hex Output buffer (size 17, NUL-terminated).
 * @param in_ddname Input 8-byte DDNAME buffer.
 * @return None.
 */
static void tso_ddname_hex(char out_hex[17], const char in_ddname[8])
{
  static const char hex[] = "0123456789ABCDEF";
  size_t i = 0;

  if (out_hex == NULL)
    return;
  out_hex[0] = '\0';
  if (in_ddname == NULL)
    return;
  for (i = 0; i < 8; i++) {
    unsigned char c = (unsigned char)in_ddname[i];
    out_hex[i * 2] = hex[c >> 4];
    out_hex[i * 2 + 1] = hex[c & 0x0F];
  }
  out_hex[16] = '\0';
}

/**
 * @brief Format a byte buffer into an uppercase hex string.
 *
 * @param out_hex Output buffer (must be at least in_len*2+1 bytes).
 * @param out_len Output buffer size in bytes.
 * @param in_buf Input byte buffer.
 * @param in_len Input buffer length in bytes.
 * @return None.
 */
static void tso_bytes_hex(char *out_hex, size_t out_len,
                          const unsigned char *in_buf, size_t in_len)
{
  static const char hex[] = "0123456789ABCDEF";
  size_t i = 0;

  if (out_hex == NULL || out_len == 0)
    return;
  out_hex[0] = '\0';
  if (in_buf == NULL)
    return;
  if (out_len < (in_len * 2 + 1))
    return;
  for (i = 0; i < in_len; i++) {
    unsigned char c = in_buf[i];
    out_hex[i * 2] = hex[c >> 4];
    out_hex[i * 2 + 1] = hex[c & 0x0F];
  }
  out_hex[in_len * 2] = '\0';
}

/* DAIR workarea layout (see IKJDAPxx macros used in src/tsodalo.asm). */
#define TSO_DAIR_DAPL_LEN 0x14
#define TSO_DAIR_DAPB08_LEN 0x54
#define TSO_DAIR_DAPB18_LEN 0x28
#define TSO_DAIR_DAPB34_LEN 0x14
#define TSO_DAIR_DAIRACB_LEN 0x2F
#define TSO_DAIR_DSNBUF_LEN 46

#define TSO_DAIR_ALIGN4(x) (((x) + 3U) & ~3U)

#define TSO_DAIR_DAPB08_OFF (TSO_DAIR_DAPL_LEN)
#define TSO_DAIR_DAPB34_OFF                                             \
  (TSO_DAIR_DAPB08_OFF + TSO_DAIR_DAPB08_LEN + TSO_DAIR_DAPB18_LEN)
#define TSO_DAIR_DSNBUF_BASE                                             \
  (TSO_DAIR_DAPB34_OFF + TSO_DAIR_DAPB34_LEN + TSO_DAIR_DAIRACB_LEN)
#define TSO_DAIR_DSNBUF_OFF ((TSO_DAIR_DSNBUF_BASE + 1) & ~1)
#define TSO_DAIR_DDNAME_OFF (TSO_DAIR_DSNBUF_OFF + TSO_DAIR_DSNBUF_LEN)
#define TSO_DAIR_R15_34_OFF                                              \
  TSO_DAIR_ALIGN4(TSO_DAIR_DDNAME_OFF + 8)
#define TSO_DAIR_R15_08_OFF (TSO_DAIR_R15_34_OFF + 4)

#define TSO_DAIR_DA08_FLG_OFF 0x02
#define TSO_DAIR_DA08_DARC_OFF 0x04
#define TSO_DAIR_DA08_CTRC_OFF 0x06
#define TSO_DAIR_DA08_DDN_OFF 0x0C

#define TSO_DAIR_DA34_FLG_OFF 0x02
#define TSO_DAIR_DA34_DARC_OFF 0x04

/**
 * @brief Read a big-endian 16-bit value from a byte buffer.
 *
 * @param buf Input buffer (must be at least 2 bytes).
 * @return 16-bit unsigned value, or 0 when buf is NULL.
 */
static unsigned int tso_dair_u16(const unsigned char *buf)
{
  if (buf == NULL)
    return 0;
  return ((unsigned int)buf[0] << 8) | (unsigned int)buf[1];
}

/**
 * @brief Read a big-endian 32-bit value from a byte buffer.
 *
 * @param buf Input buffer (must be at least 4 bytes).
 * @return 32-bit unsigned value, or 0 when buf is NULL.
 */
static unsigned int tso_dair_u32(const unsigned char *buf)
{
  if (buf == NULL)
    return 0;
  return ((unsigned int)buf[0] << 24) | ((unsigned int)buf[1] << 16) |
         ((unsigned int)buf[2] << 8) | (unsigned int)buf[3];
}
/**
 * @brief Read DAIR outputs for OUTDD from the workarea.
 *
 * @param work Workarea base address (TSODAIR_WORKSIZE bytes).
 * @param out_dair_rc Output DA08DARC (dynamic allocation reason).
 * @param out_cat_rc Output DA08CTRC (catalog reason).
 * @param out_flg Output DA08FLG (secondary error flags).
 * @param out_ddname Output DA08DDN (8-byte DDNAME).
 * @param out_da34_darc Output DA34DARC (attribute list reason).
 * @param out_da34_flg Output DA34FLG (attribute list flags).
 * @return None.
 */
static void tso_dair_read_outdd(const unsigned char *work, int *out_dair_rc,
                                int *out_cat_rc, int *out_flg,
                                char out_ddname[8], int *out_da34_darc,
                                int *out_da34_flg, int *out_r15_34,
                                int *out_r15_08)
{
  const unsigned char *dapb08 = NULL;
  const unsigned char *dapb34 = NULL;

  if (work == NULL)
    return;
  dapb08 = work + TSO_DAIR_DAPB08_OFF;
  dapb34 = work + TSO_DAIR_DAPB34_OFF;
  if (out_dair_rc)
    *out_dair_rc =
        (int)tso_dair_u16(dapb08 + TSO_DAIR_DA08_DARC_OFF);
  if (out_cat_rc)
    *out_cat_rc =
        (int)tso_dair_u16(dapb08 + TSO_DAIR_DA08_CTRC_OFF);
  if (out_flg)
    *out_flg = (int)tso_dair_u16(dapb08 + TSO_DAIR_DA08_FLG_OFF);
  if (out_ddname != NULL)
    memcpy(out_ddname, dapb08 + TSO_DAIR_DA08_DDN_OFF, 8);
  if (out_da34_darc)
    *out_da34_darc =
        (int)tso_dair_u16(dapb34 + TSO_DAIR_DA34_DARC_OFF);
  if (out_da34_flg)
    *out_da34_flg =
        (int)tso_dair_u16(dapb34 + TSO_DAIR_DA34_FLG_OFF);
  if (out_r15_34)
    *out_r15_34 = (int)tso_dair_u32(work + TSO_DAIR_R15_34_OFF);
  if (out_r15_08)
    *out_r15_08 = (int)tso_dair_u32(work + TSO_DAIR_R15_08_OFF);
}

/**
 * @brief Read the DAIR DSNAME buffer from the workarea.
 *
 * @param work Workarea base address (TSODAIR_WORKSIZE bytes).
 * @param out_len Output DSNAME length (0-44).
 * @param out_hex Output hex dump of the 44-byte DSNAME buffer (size 89).
 * @return None.
 */
static void tso_dair_read_dsbuf(const unsigned char *work, int *out_len,
                                char out_hex[89])
{
  const unsigned char *dsn = NULL;
  unsigned int len = 0;

  if (out_len)
    *out_len = 0;
  if (out_hex)
    out_hex[0] = '\0';
  if (work == NULL)
    return;
  dsn = work + TSO_DAIR_DSNBUF_OFF;
  len = tso_dair_u16(dsn);
  if (len > 44)
    len = 44;
  if (out_len)
    *out_len = (int)len;
  if (out_hex)
    tso_bytes_hex(out_hex, 89, dsn + 2, 44);
}

/**
 * @brief Call STACK via TSOSTK for OUTDD/CLOSE/DELETE operations.
 *
 * @param outdd_name DDNAME string (1-8 chars) or NULL for CLOSE/DELETE.
 * @param op STACK operation selector (TSO_STK_*).
 * @param out_rc Output STACK return code.
 * @return 0 on success, or LUZ_E_TSO_CMD on failure.
 */
static int tso_stack_call(const char *outdd_name, int op, int *out_rc)
{
  void *cppl = NULL;
  char ddname[8];
  int rc = 0;

  if (g_cppl_addr == 0)
    return LUZ_E_TSO_CMD;
  cppl = (void *)(uintptr_t)g_cppl_addr;
  if (op == TSO_STK_OUTDD) {
    tso_ddname_pad(ddname, outdd_name);
    rc = TSOSTK(cppl, ddname, op);
  } else {
    rc = TSOSTK(cppl, NULL, op);
  }
  if (out_rc)
    *out_rc = rc;
  if (rc != 0)
    return LUZ_E_TSO_CMD;
  return 0;
}

/**
 * @brief Route output to a preallocated DDNAME via STACK.
 *
 * @param outdd_name DDNAME string (1-8 chars).
 * @param out_rc Output STACK return code.
 * @return 0 on success, or LUZ_E_TSO_CMD on failure.
 */
static int tso_stack_outdd(const char *outdd_name, int *out_rc)
{
  /* Change note: use STACK OUTDD instead of SYSTSPRT reallocation.
   * Problem: SYSTSPRT is open under TMP and cannot be reallocated.
   * Expected effect: tso.cmd output routes to OUTDD dataset.
   * Impact: output capture works without SYSTSPRT manipulation.
   * Ref: src/tso.c.md#tso-stack-outdd
   */
  return tso_stack_call(outdd_name, TSO_STK_OUTDD, out_rc);
}

/**
 * @brief Close STACK dataset DCBs to enable DDNAME reading.
 *
 * @param out_rc Output STACK return code.
 * @return 0 on success, or LUZ_E_TSO_CMD on failure.
 */
static int tso_stack_close(int *out_rc)
{
  /* Change note: close STACK dataset DCBs after command execution.
   * Problem: output DD cannot be read while the DCB remains open.
   * Expected effect: DDNAME is readable after CLOSE.
   * Impact: tso.cmd can read output data immediately.
   * Ref: src/tso.c.md#tso-stack-outdd
   */
  return tso_stack_call(NULL, TSO_STK_CLOSE, out_rc);
}

/**
 * @brief Delete the top STACK element after output capture.
 *
 * @param out_rc Output STACK return code.
 * @return 0 on success, or LUZ_E_TSO_CMD on failure.
 */
static int tso_stack_delete(int *out_rc)
{
  /* Change note: pop the dataset element to restore the I/O stack.
   * Problem: leaving dataset element on stack can misroute later I/O.
   * Expected effect: STACK top element is removed after use.
   * Impact: tso.cmd does not leak stack elements across calls.
   * Ref: src/tso.c.md#tso-stack-outdd
   */
  return tso_stack_call(NULL, TSO_STK_DELETE, out_rc);
}

/**
 * @brief Allocate a temporary OUTDD target for command output.
 *
 * Change note: allocate a temporary OUTDD dataset using DAIR.
 * Problem: TSO ALLOC rejects && temp DSNs in TMP and can collide after abends.
 * Expected effect: DAIR allocates a temp DSN and avoids duplicate-name errors.
 * Impact: output capture uses a temp dataset that is deleted on unallocate.
 * Ref: src/tso.c.md#tso-dair-outdd
 *
 * @param out_cmd_rc Output command return code from ALLOC.
 * @param out_cmd_rsn Output reason code from ALLOC.
 * @param out_cmd_abend Output abend code from ALLOC.
 * @param out_cmd_flg Output DAIR flag byte from ALLOC.
 * @param out_ddname Output DDNAME string chosen by DAIR (size 9).
 * @param out_ddhex Output DDNAME hex string chosen by DAIR (size 17).
 * @param out_da34_darc Output DAIR X'34' DARC.
 * @param out_da34_flg Output DAIR X'34' flag bytes.
 * @param out_da_r15_34 Output DAIR R15 for X'34'.
 * @param out_da_r15_08 Output DAIR R15 for X'08'.
 * @param out_dslen Output DSNAME length from DAIR buffer.
 * @param out_dshex Output DSNAME hex buffer (size 89).
 * @return 0 on success, or LUZ_E_TSO_CMD on failure.
 */
static int tso_alloc_outdd(int *out_cmd_rc, int *out_cmd_rsn,
                           int *out_cmd_abend, int *out_cmd_flg,
                           char out_ddname[9], char out_ddhex[17],
                           int *out_da34_darc, int *out_da34_flg,
                           int *out_da_r15_34, int *out_da_r15_08,
                           int *out_dslen, char out_dshex[89])
{
  int rc = 0;
  int dair_rc = 0;
  int cat_rc = 0;
  int da34_darc = 0;
  int da34_flg = 0;
  int da_r15_34 = 0;
  int da_r15_08 = 0;
  void *cppl = NULL;
  void *work = NULL;
  char ddname_raw[8];
  char ddname[9];

  if (g_cppl_addr == 0)
    return LUZ_E_TSO_CMD;
  cppl = (void *)(uintptr_t)g_cppl_addr;
  work = __malloc31(TSODAIR_WORKSIZE);
  if (work == NULL)
    return LUZ_E_TSO_CMD;
  memset(work, 0, TSODAIR_WORKSIZE);
  memset(ddname_raw, ' ', sizeof(ddname_raw));
  tso_ddname_pad(ddname, g_tso_outdd_name);
  ddname[8] = '\0';
  /* Change note: use DAIR wrapper to allocate a temp DSN for OUTDD.
   * Problem: TSO ALLOC rejects && temp DSNs under IKJEFTSR.
   * Expected effect: TSODALC allocates &&LZ<DDNAME> and returns RCs.
   * Impact: OUTDD is temporary and auto-deleted on unallocate.
   * Ref: src/tso.c.md#tso-dair-outdd
   */
  /* Change note: capture DAIR flag byte for secondary error reporting.
   * Problem: DAIR alloc could succeed with secondary errors (DA08FLG).
   * Expected effect: callers can log DA08FLG alongside rc/dair/cat.
   * Impact: STACK failure diagnostics include DAIR secondary flags.
   * Ref: src/tso.c.md#tso-dair-outdd
   */
  /* Change note: capture DAIR-returned DDNAME for STACK routing.
   * Problem: DAIR may allocate a DDNAME different from the requested one.
   * Expected effect: OUTDD uses the actual DAIR-assigned DDNAME.
   * Impact: avoids DDNAME-missing errors when DAIR renames the allocation.
   * Ref: src/tso.c.md#tso-dair-outdd
   */
  /* Change note: read DAIR outputs directly from workarea.
   * Problem: storing outputs to caller memory after IKJDAIR abends.
   * Expected effect: C parses DAIR outputs from DAPB in the workarea.
   * Impact: tso.cmd still reports DAIR diagnostics without ASM stores.
   * Ref: src/tso.c.md#tso-dair-outdd
   */
  rc = tsodalo_call(cppl, ddname, work);
  tso_dair_read_outdd((const unsigned char *)work, &dair_rc, &cat_rc,
                      out_cmd_flg, ddname_raw, &da34_darc, &da34_flg,
                      &da_r15_34, &da_r15_08);
  /* Change note: capture DAIR DSNAME buffer for diagnostics.
   * Problem: empty DDNAME needs DSNAME evidence to validate inputs.
   * Expected effect: diagnostics include DAIR DSNAME hex/length.
   * Impact: troubleshoot input plist issues without ASM changes.
   * Ref: src/tso.c.md#tso-dair-outdd
   */
  tso_dair_read_dsbuf((const unsigned char *)work, out_dslen, out_dshex);
  free(work);
  if (out_cmd_rc)
    *out_cmd_rc = rc;
  if (out_cmd_rsn)
    *out_cmd_rsn = dair_rc;
  if (out_cmd_abend)
    *out_cmd_abend = cat_rc;
  /* Change note: keep DAIR flag byte even on allocation failure.
   * Problem: clearing DA08FLG hides secondary error indicators.
   * Expected effect: callers see DA08FLG for successful and failed calls.
   * Impact: tso.cmd logs secondary DAIR diagnostics consistently.
   * Ref: src/tso.c.md#tso-dair-outdd
   */
  if (out_da34_darc)
    *out_da34_darc = da34_darc;
  if (out_da34_flg)
    *out_da34_flg = da34_flg;
  if (out_da_r15_34)
    *out_da_r15_34 = da_r15_34;
  if (out_da_r15_08)
    *out_da_r15_08 = da_r15_08;
  if (out_ddname != NULL) {
    tso_ddname_unpad(out_ddname, ddname_raw);
    /* Change note: do not fallback to a default DDNAME when DAIR
     * returns blanks.
     * Problem: fallback hides the real allocation failure.
     * Expected effect: callers see an empty DDNAME when DAIR did not
     * return one.
     * Impact: STACK/open diagnostics reflect the actual DAIR result.
     * Ref: src/tso.c.md#tso-dair-outdd
     */
  }
  /* Change note: expose raw DDNAME bytes as hex for diagnostics.
   * Problem: EBCDIC blanks/nonprintables make DDNAME hard to inspect.
   * Expected effect: diagnostics can show raw DAIR-returned bytes.
   * Impact: troubleshooting distinguishes blank vs real DDNAME values.
   * Ref: src/tso.c.md#tso-dair-outdd
   */
  if (out_ddhex != NULL)
    tso_ddname_hex(out_ddhex, ddname_raw);
  if (rc != 0)
    return LUZ_E_TSO_CMD;
  return 0;
}

/**
 * @brief Free the temporary OUTDD allocation after command execution.
 *
 * Change note: free OUTDD DDNAME after reading output.
 * Problem: leaving OUTDD allocated consumes DDNAMEs and keeps DCBs open.
 * Expected effect: OUTDD is freed; temp DSN is deleted on unallocate.
 * Impact: tso.cmd cleans up its output DDNAME each call.
 * Ref: src/tso.c.md#tso-stack-outdd
 *
 * @param outdd_name DDNAME to free (NULL uses default).
 * @param out_cmd_rc Output command return code from FREE.
 * @param out_cmd_rsn Output reason code from FREE.
 * @param out_cmd_abend Output abend code from FREE.
 * @return 0 on success, or LUZ_E_TSO_CMD on failure.
 */
static int tso_free_outdd(const char *outdd_name, int *out_cmd_rc,
                          int *out_cmd_rsn, int *out_cmd_abend)
{
  int rc = 0;
  int dair_rc = 0;
  int cat_rc = 0;
  void *cppl = NULL;
  void *work = NULL;
  char ddname[9];

  if (g_cppl_addr == 0)
    return LUZ_E_TSO_CMD;
  cppl = (void *)(uintptr_t)g_cppl_addr;
  work = __malloc31(TSODAIR_WORKSIZE);
  if (work == NULL)
    return LUZ_E_TSO_CMD;
  memset(work, 0, TSODAIR_WORKSIZE);
  tso_ddname_pad(ddname, outdd_name ? outdd_name : g_tso_outdd_name);
  ddname[8] = '\0';
  /* Change note: use DAIR wrapper to free temp OUTDD allocation.
   * Problem: TSO FREE does not apply to DAIR-allocated temp DSNs.
   * Expected effect: TSODFRE releases DDNAME and deletes temp dataset.
   * Impact: OUTDD cleanup is handled via DAIR unallocate.
   * Ref: src/tso.c.md#tso-dair-outdd
   */
  rc = tsodflo_call(cppl, ddname, &dair_rc, &cat_rc, work);
  free(work);
  if (out_cmd_rc)
    *out_cmd_rc = rc;
  if (out_cmd_rsn)
    *out_cmd_rsn = dair_rc;
  if (out_cmd_abend)
    *out_cmd_abend = cat_rc;
  if (rc != 0)
    return LUZ_E_TSO_CMD;
  return 0;
}

/**
 * @brief Read DDNAME output into a Lua table with LUZNNNNN-prefixed lines.
 *
 * Change note: align prefix format to LUZNNNNN.
 * Problem: prior wording used LUZNNNNN formatting inconsistently in docs.
 * Expected effect: documentation matches emitted message format.
 * Impact: comment-only change; no runtime behavior is altered.
 *
 * @param L Lua state.
 * @param ddname DDNAME to read (EBCDIC, 1-8 chars).
 * @return 1 on success, 0 on failure.
 */
static int read_dd_to_lines(lua_State *L, const char *ddname)
{
  char path[32];
  char alt_path[32];
  FILE *fp;
  char buf[2048];
  char *rec = NULL;
  size_t rec_cap = 32760u;
  int record_io = 0;
  int idx = 0;
  size_t bytes_read = 0;
  size_t skip_bytes = 0;
  int is_systsprt = 0;
  int skip_failed = 0;
  char skip_buf[2048];

  if (ddname == NULL || ddname[0] == '\0')
    return 0;
  if (snprintf(path, sizeof(path), "DD:%s", ddname) <= 0)
    return 0;
  if (snprintf(alt_path, sizeof(alt_path), "//DD:%s", ddname) <= 0)
    alt_path[0] = '\0';
  if (strcmp(ddname, "SYSTSPRT") == 0) {
    is_systsprt = 1;
    skip_bytes = g_systsprt_offset;
  }
  /* Change note: prefer record I/O for DD output capture.
   * Problem: stream I/O can mis-handle fixed record datasets (FB/VB).
   * Expected effect: read records via fread and normalize line endings.
   * Impact: tso.cmd output works for FB/VB SYSTSPRT datasets.
   * Ref: src/tso.md#read-dd-record-io
   */
reopen_dd:
  /* Change note: try both DD: and //DD: prefixes for SYSOUT datasets.
   * Problem: some JES allocations reject DD: opens for SYSOUT DDNAMEs.
   * Expected effect: fallback path enables reading SYSTSPRT in TMP jobs.
   * Impact: tso.cmd output capture succeeds for SYSOUT-backed DDNAMEs.
   * Ref: src/tso.md#read-dd-record-io
   */
  fp = fopen(path, "rb,type=record");
  if (fp != NULL) {
    record_io = 1;
  } else {
    fp = fopen(path, "rb");
  }
  if (fp == NULL && alt_path[0] != '\0') {
    fp = fopen(alt_path, "rb,type=record");
    if (fp != NULL) {
      record_io = 1;
    } else {
      fp = fopen(alt_path, "rb");
    }
  }
  if (fp == NULL)
    return 0;

  if (record_io) {
    rec = (char *)malloc(rec_cap);
    if (rec == NULL) {
      fclose(fp);
      return 0;
    }
  }

  if (skip_bytes > 0) {
    size_t remaining = skip_bytes;
    char *skip_ptr = record_io ? rec : skip_buf;
    size_t skip_cap = record_io ? rec_cap : sizeof(skip_buf);
    /* Change note: skip prior SYSTSPRT bytes to return per-call output.
     * Problem: successive tso.cmd calls would accumulate old lines.
     * Expected effect: only new SYSTSPRT content is returned each call.
     * Impact: per-command output is isolated within one LUAEXEC run.
     * Ref: src/tso.md#tso-clean-c
     */
    while (remaining > 0) {
      size_t to_read = record_io ? skip_cap :
                       (remaining < skip_cap ? remaining : skip_cap);
      size_t n = fread(skip_ptr, 1u, to_read, fp);
      if (n == 0) {
        if (ferror(fp)) {
          if (rec != NULL)
            free(rec);
          fclose(fp);
          return 0;
        }
        skip_failed = 1;
        break;
      }
      if (n >= remaining)
        remaining = 0;
      else
        remaining -= n;
    }
    if (skip_failed && is_systsprt && g_systsprt_offset != 0) {
      fclose(fp);
      if (rec != NULL) {
        free(rec);
        rec = NULL;
      }
      g_systsprt_offset = 0;
      skip_bytes = 0;
      skip_failed = 0;
      goto reopen_dd;
    }
  }

  lua_newtable(L);
  if (record_io) {
    while (1) {
      size_t n = fread(rec, 1u, rec_cap, fp);
      if (n == 0) {
        if (ferror(fp)) {
          free(rec);
          fclose(fp);
          return 0;
        }
        break;
      }
      bytes_read += n;
      while (n > 0 &&
             (rec[n - 1] == ' ' || rec[n - 1] == '\0' ||
              rec[n - 1] == '\r' || rec[n - 1] == '\n')) {
        n--;
      }
      lua_pushstring(L, "LUZ30031 ");
      lua_pushlstring(L, rec, n);
      lua_concat(L, 2);
      lua_rawseti(L, -2, ++idx);
    }
    free(rec);
  } else {
    while (fgets(buf, sizeof(buf), fp) != NULL) {
      size_t raw_len = strlen(buf);
      size_t len = strcspn(buf, "\r\n");
      bytes_read += raw_len;
      lua_pushstring(L, "LUZ30031 ");
      lua_pushlstring(L, buf, len);
      lua_concat(L, 2);
      lua_rawseti(L, -2, ++idx);
    }
  }
  fclose(fp);
  if (is_systsprt)
    g_systsprt_offset += bytes_read;
  return 1;
}

/**
 * @brief Sync SYSTSPRT offset to current end-of-file.
 *
 * Change note: sync SYSTSPRT offset before REXX capture.
 * Problem: capture=true must return only new OUTTRAP output.
 * Expected effect: previous SYSTSPRT content is skipped.
 * Impact: tso.cmd capture returns per-call output only.
 * Ref: src/tso.c.md#tso-rexx-outtrap
 */
static void tso_sync_systsprt_offset(void)
{
  char path[32];
  char alt_path[32];
  FILE *fp;
  char buf[2048];
  char *rec = NULL;
  size_t rec_cap = 32760u;
  size_t bytes = 0;
  int record_io = 0;

  if (snprintf(path, sizeof(path), "DD:%s", "SYSTSPRT") <= 0)
    return;
  if (snprintf(alt_path, sizeof(alt_path), "//DD:%s", "SYSTSPRT") <= 0)
    alt_path[0] = '\0';
  fp = fopen(path, "rb,type=record");
  if (fp != NULL) {
    record_io = 1;
  } else {
    fp = fopen(path, "rb");
  }
  if (fp == NULL && alt_path[0] != '\0') {
    fp = fopen(alt_path, "rb,type=record");
    if (fp != NULL) {
      record_io = 1;
    } else {
      fp = fopen(alt_path, "rb");
    }
  }
  if (fp == NULL) {
    g_systsprt_offset = 0;
    return;
  }

  if (record_io) {
    rec = (char *)malloc(rec_cap);
    if (rec == NULL) {
      fclose(fp);
      g_systsprt_offset = 0;
      return;
    }
  }

  while (1) {
    size_t cap = record_io ? rec_cap : sizeof(buf);
    char *dst = record_io ? rec : buf;
    size_t n = fread(dst, 1u, cap, fp);
    if (n == 0)
      break;
    bytes += n;
  }
  if (rec != NULL)
    free(rec);
  fclose(fp);
  g_systsprt_offset = bytes;
}

/**
 * @brief Execute a TSO command via IKJEFTSR without output capture.
 *
 * @param L Lua state.
 * @param cmd Command text (EBCDIC).
 * @return Number of Lua return values pushed.
 */
static int lua_tso_cmd_nocap(lua_State *L, const char *cmd)
{
  int svc_rc = 0;
  int cmd_rc = 0;
  int cmd_rsn = 0;
  int cmd_abend = 0;

  if (tso_env_init() != 0) {
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30047 tso.cmd TSO environment unavailable");
    lua_pushinteger(L, LUZ_E_TSO_CMD);
    return 3;
  }

  svc_rc = tso_ikjeftsr_call(cmd, &cmd_rc, &cmd_rsn, &cmd_abend);
  if (svc_rc != 0) {
    lua_pushnil(L);
    lua_pushfstring(L,
                    "LUZ30032 tso.cmd failed native reason=%d abend=%d",
                    cmd_rsn, cmd_abend);
    lua_pushinteger(L, LUZ_E_TSO_CMD);
    return 3;
  }
  lua_pushinteger(L, cmd_rc);
  lua_pushnil(L);
  return 2;
}

/**
 * @brief Execute a TSO command via REXX + OUTTRAP capture.
 *
 * @param L Lua state.
 * @param cmd Command text (EBCDIC).
 * @return Number of Lua return values pushed.
 */
static int lua_tso_cmd_capture(lua_State *L, const char *cmd)
{
  int rc = 0;

  if (tso_env_init() != 0) {
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30047 tso.cmd TSO environment unavailable");
    lua_pushinteger(L, LUZ_E_TSO_CMD);
    return 3;
  }

  /* Change note: use REXX OUTTRAP for capture=true path.
   * Problem: IKJEFTSR batch output always targets SYSTSPRT.
   * Expected effect: LUTSO returns only command output via OUTTRAP.
   * Impact: capture=true yields output without DD/STACK routing.
   * Ref: src/tso.c.md#tso-rexx-outtrap
   */
  tso_sync_systsprt_offset();
  rc = tso_call_rexx("SYSEXEC", "LUTSO", "CMD", cmd, "SYSTSPRT",
                     LUZ_E_TSO_CMD);
  if (rc == LUZ_E_TSO_CMD && g_last_irx_rc != 0) {
    lua_pushnil(L);
    lua_pushfstring(L,
                    "LUZ30032 tso.cmd failed rexx irx_rc=%d rexx_rc=%d",
                    g_last_irx_rc, g_last_rexx_rc);
    lua_pushinteger(L, LUZ_E_TSO_CMD);
    return 3;
  }
  lua_pushinteger(L, rc);
  if (!read_dd_to_lines(L, "SYSTSPRT")) {
    lua_newtable(L);
  }
  return 2;
}

/**
 * @brief Invoke the LUTSO REXX exec via IRXEXEC for TSO command processing.
 *
 * Change note: restrict REXX use to capture=true (OUTTRAP) path.
 * Problem: we need output capture without ASM, but want C-first defaults.
 * Expected effect: REXX runs only when capture is requested explicitly.
 * Impact: default tso.cmd stays on IKJEFTSR without REXX.
 *
 * @param ddname DDNAME containing the REXX exec library.
 * @param member REXX exec member name.
 * @param mode Execution mode string (TSO/PGM).
 * @param payload Command payload string.
 * @param outdd Output DDNAME for command output capture.
 * @param errcode Error RC to return on failure.
 * @return 0 on success, or errcode on failure.
 */
static int tso_call_rexx(const char *ddname, const char *member,
                         const char *mode, const char *payload,
                         const char *outdd, int errcode)
{
  EXECBLK_type execblk;
  EXECBLK_type *execblk_ptr = &execblk;
  one_parameter_type args[4];
  one_parameter_type *argtable = args;
  IRXEXEC_type parm;
  int flags = 0;
  int rexx_rc = 0;
  int dummy_zero = 0;
  int eval_rc = 0;
  EVALBLK_type evalblk;
  EVALBLK_type *evalblk_ptr = &evalblk;
  irxexec_fn irxexec;
  int rc;

  printf("LUZ00015 tso_call_rexx enter dd=%s member=%s mode=%s outdd=%s\n",
         ddname ? ddname : "", member ? member : "", mode ? mode : "",
         outdd ? outdd : "");
  fflush(NULL);

  if (tso_env_init() != 0)
    return errcode;

  irxexec = (irxexec_fn)fetch("IRXEXEC");
  if (irxexec == NULL) {
    g_last_irx_rc = -2;
    g_last_rexx_rc = 0;
    return errcode;
  }

  memset(&execblk, 0, sizeof(execblk));
  memset(&args, 0, sizeof(args));
  memset(&parm, 0, sizeof(parm));
  memset(&evalblk, 0, sizeof(evalblk));
  evalblk.EVSIZE = 34;

  memcpy(execblk.EXECBLK_ACRYN, "IRXEXECB", 8);
  execblk.EXECBLK_LENGTH = 48;
  memset(execblk.EXECBLK_MEMBER, ' ', sizeof(execblk.EXECBLK_MEMBER));
  memset(execblk.EXECBLK_DDNAME, ' ', sizeof(execblk.EXECBLK_DDNAME));
  memset(execblk.EXECBLK_SUBCOM, ' ', sizeof(execblk.EXECBLK_SUBCOM));
  if (member)
    memcpy(execblk.EXECBLK_MEMBER, member, strlen(member) > 8 ? 8 : strlen(member));
  if (ddname)
    memcpy(execblk.EXECBLK_DDNAME, ddname, strlen(ddname) > 8 ? 8 : strlen(ddname));
  memcpy(execblk.EXECBLK_SUBCOM, "TSO", 3);

  args[0].ARGSTRING_PTR = (void *)(mode ? mode : "");
  args[0].ARGSTRING_LENGTH = (int)strlen(mode ? mode : "");
  args[1].ARGSTRING_PTR = (void *)(payload ? payload : "");
  args[1].ARGSTRING_LENGTH = (int)strlen(payload ? payload : "");
  args[2].ARGSTRING_PTR = (void *)(outdd ? outdd : "");
  args[2].ARGSTRING_LENGTH = (int)strlen(outdd ? outdd : "");
  args[3].ARGSTRING_PTR = (void *)-1;
  args[3].ARGSTRING_LENGTH = -1;

  parm.execblk_ptr = &execblk_ptr;
  parm.argtable_ptr = &argtable;
  parm.flags_ptr = &flags;
  parm.instblk_ptr = NULL;
  if (g_cppl_addr != 0)
    parm.cppl_ptr = (int *)(uintptr_t)g_cppl_addr;
  else
    parm.cppl_ptr = NULL;
  parm.evalblk_ptr = &evalblk_ptr;
  parm.workarea_ptr = NULL;
  parm.userfield_ptr = NULL;
  parm.envblock_ptr = NULL;
  parm.rexx_rc_ptr = &rexx_rc;
  parm.rexx_rc_ptr = (int *)((uintptr_t)parm.rexx_rc_ptr | (uintptr_t)0x80000000u);

  flags = 0x40000000;
  rc = irxexec(parm);

  g_last_irx_rc = rc;
  if (rc != 0) {
    g_last_rexx_rc = rexx_rc;
    printf("LUZ00016 tso_call_rexx irx_rc=%d rexx_rc=%d\n", rc, rexx_rc);
    fflush(NULL);
    return errcode;
  }
  if (!evalblk_to_rc(&evalblk, &eval_rc)) {
    g_last_rexx_rc = rexx_rc;
    g_last_irx_rc = -3;
    printf("LUZ00016 tso_call_rexx eval_rc parse failed rexx_rc=%d\n", rexx_rc);
    fflush(NULL);
    return errcode;
  }
  g_last_rexx_rc = eval_rc;
  printf("LUZ00016 tso_call_rexx irx_rc=0 rexx_rc=%d\n", eval_rc);
  fflush(NULL);
  return eval_rc;
}

/**
 * @brief Lua binding for tso.cmd (execute a TSO command).
 *
 * @param L Lua state.
 * @return Number of Lua return values pushed.
 */
static int l_tso_cmd(lua_State *L)
{
  const char *cmd = luaL_checkstring(L, 1);
  int capture = 0;
  if (!lua_isnoneornil(L, 2)) {
    luaL_checktype(L, 2, LUA_TBOOLEAN);
    capture = lua_toboolean(L, 2);
  }

  lua_getglobal(L, "LUAZ_MODE");
  if (!lua_isstring(L, -1) || strcmp(lua_tostring(L, -1), "TSO") != 0) {
    lua_pop(L, 1);
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30045 tso.cmd not available in PGM mode");
    lua_pushinteger(L, LUZ_E_TSO_CMD);
    return 3;
  }
  lua_pop(L, 1);

  /* Change note: add capture flag to select output handling.
   * Problem: callers need a no-capture path and a capture path without ASM.
   * Expected effect: capture=true uses REXX OUTTRAP, false uses IKJEFTSR only.
   * Impact: tso.cmd defaults to no output capture unless requested.
   * Ref: src/tso.c.md#tso-rexx-outtrap
   */
  if (capture)
    return lua_tso_cmd_capture(L, cmd);
  return lua_tso_cmd_nocap(L, cmd);
}

/**
 * @brief Lua binding for tso.alloc (dynamic allocation).
 *
 * @param L Lua state.
 * @return Number of Lua return values pushed.
 */
static int l_tso_alloc(lua_State *L)
{
  const char *spec = luaL_checkstring(L, 1);
  lua_getglobal(L, "LUAZ_MODE");
  if (!lua_isstring(L, -1) || strcmp(lua_tostring(L, -1), "TSO") != 0) {
    lua_pop(L, 1);
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30045 tso.alloc not available in PGM mode");
    lua_pushinteger(L, LUZ_E_TSO_ALLOC);
    return 3;
  }
  lua_pop(L, 1);
  /* Change note: enforce direct TSO allocation path (no REXX).
   * Problem: REXX execution is out of scope without explicit approval.
   * Expected effect: tso.alloc uses native TSO path only.
   * Impact: tso.alloc returns native failure when not implemented.
   */
  int rc = tso_native_alloc(spec);
  if (rc == LUZ_E_TSO_ALLOC) {
    lua_pushnil(L);
    lua_pushfstring(L, "LUZ30033 tso.alloc failed native rc=%d", rc);
    lua_pushinteger(L, rc);
    return 3;
  }
  lua_pushinteger(L, rc);
  return 1;
}

/**
 * @brief Lua binding for tso.free (dynamic deallocation).
 *
 * @param L Lua state.
 * @return Number of Lua return values pushed.
 */
static int l_tso_free(lua_State *L)
{
  const char *spec = luaL_checkstring(L, 1);
  lua_getglobal(L, "LUAZ_MODE");
  if (!lua_isstring(L, -1) || strcmp(lua_tostring(L, -1), "TSO") != 0) {
    lua_pop(L, 1);
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30045 tso.free not available in PGM mode");
    lua_pushinteger(L, LUZ_E_TSO_FREE);
    return 3;
  }
  lua_pop(L, 1);
  /* Change note: enforce direct TSO deallocation path (no REXX).
   * Problem: REXX execution is out of scope without explicit approval.
   * Expected effect: tso.free uses native TSO path only.
   * Impact: tso.free returns native failure when not implemented.
   */
  int rc = tso_native_free(spec);
  if (rc == LUZ_E_TSO_FREE) {
    lua_pushnil(L);
    lua_pushfstring(L, "LUZ30034 tso.free failed native rc=%d", rc);
    lua_pushinteger(L, rc);
    return 3;
  }
  lua_pushinteger(L, rc);
  return 1;
}

/**
 * @brief Lua binding for tso.msg (emit a TSO message).
 *
 * @param L Lua state.
 * @return Number of Lua return values pushed.
 */
static int l_tso_msg(lua_State *L)
{
  const char *text = luaL_checkstring(L, 1);
  int level = (int)luaL_optinteger(L, 2, 0);
  lua_getglobal(L, "LUAZ_MODE");
  if (!lua_isstring(L, -1) || strcmp(lua_tostring(L, -1), "TSO") != 0) {
    lua_pop(L, 1);
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30045 tso.msg not available in PGM mode");
    lua_pushinteger(L, LUZ_E_TSO_MSG);
    return 3;
  }
  lua_pop(L, 1);
  int rc = lua_tso_msg(text, level);
  if (rc == LUZ_E_TSO_MSG) {
    lua_pushnil(L);
    lua_pushfstring(L, "LUZ30035 tso.msg failed irx_rc=%d rexx_rc=%d",
                    g_last_irx_rc, g_last_rexx_rc);
    lua_pushinteger(L, rc);
    return 3;
  }
  lua_pushinteger(L, rc);
  return 1;
}

/**
 * @brief Lua binding for tso.exit (terminate with RC).
 *
 * @param L Lua state.
 * @return Number of Lua return values pushed.
 */
static int l_tso_exit(lua_State *L)
{
  int code = (int)luaL_optinteger(L, 1, 0);
  lua_getglobal(L, "LUAZ_MODE");
  if (!lua_isstring(L, -1) || strcmp(lua_tostring(L, -1), "TSO") != 0) {
    lua_pop(L, 1);
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30045 tso.exit not available in PGM mode");
    lua_pushinteger(L, LUZ_E_TSO_EXIT);
    return 3;
  }
  lua_pop(L, 1);
  lua_tso_exit(code);
  return 0;
}

/**
 * @brief Lua module entrypoint for tso.* functions.
 *
 * @param L Lua state.
 * @return 1 on success (module table on stack).
 */
int luaopen_tso(lua_State *L)
{
  static const luaL_Reg lib[] = {
    {"cmd", l_tso_cmd},
    {"alloc", l_tso_alloc},
    {"free", l_tso_free},
    {"msg", l_tso_msg},
    {"exit", l_tso_exit},
    {NULL, NULL}
  };
  luaL_newlib(L, lib);
  return 1;
}

/**
 * @brief Execute a TSO command and return a status code.
 *
 * @param cmd NUL-terminated TSO command string (EBCDIC).
 * @return 0 on success, or LUZ_E_TSO_CMD on failure.
 */
int lua_tso_cmd(const char *cmd)
{
  int svc_rc = 0;
  int cmd_rc = 0;
  int cmd_rsn = 0;
  int cmd_abend = 0;
  if (cmd == NULL)
    return LUZ_E_TSO_CMD;
  /* Change note: use clean C IKJEFTSR path for C API.
   * Problem: native TSO path depends on CPPL sharing between LUACMD/LUAEXEC.
   * Expected effect: C API uses IKJEFTSR without native CPPL path.
   * Impact: returns LUZ_E_TSO_CMD when TSO env is unavailable.
   * Ref: src/tso.md#tso-clean-c
   */
  if (tso_env_init() != 0)
    return LUZ_E_TSO_CMD;
  /* Change note: route IKJEFTSR calls through OS linkage plist helper.
   * Problem: direct calls cannot attach CPPL optional parameters.
   * Expected effect: CPPL is forwarded when cached from LUACMD.
   * Impact: C API aligns with tso.cmd CPPL behavior.
   * Ref: src/tso.c.md#ikjeftsr-param8-cppl
   */
  svc_rc = tso_ikjeftsr_call(cmd, &cmd_rc, &cmd_rsn, &cmd_abend);
  if (svc_rc != 0)
    return LUZ_E_TSO_CMD;
  return cmd_rc;
}

/**
 * @brief Allocate a dataset or DD using native TSO services.
 *
 * @param spec Allocation specification string.
 * @return 0 on success, or LUZ_E_TSO_ALLOC on failure.
 */
int lua_tso_alloc(const char *spec)
{
  int rc;
  if (spec == NULL)
    return LUZ_E_TSO_ALLOC;
  /* Change note: enforce direct TSO allocation path (no REXX).
   * Problem: REXX execution is out of scope without explicit approval.
   * Expected effect: use native DAIR path when implemented.
   * Impact: returns LUZ_E_TSO_ALLOC until native path is implemented.
   */
  rc = tso_native_alloc(spec);
  return rc;
}

/**
 * @brief Free a dataset or DD allocation using native TSO services.
 *
 * @param spec Deallocation specification string.
 * @return 0 on success, or LUZ_E_TSO_FREE on failure.
 */
int lua_tso_free(const char *spec)
{
  int rc;
  if (spec == NULL)
    return LUZ_E_TSO_FREE;
  /* Change note: enforce direct TSO deallocation path (no REXX).
   * Problem: REXX execution is out of scope without explicit approval.
   * Expected effect: use native DAIR path when implemented.
   * Impact: returns LUZ_E_TSO_FREE until native path is implemented.
   */
  rc = tso_native_free(spec);
  return rc;
}

/**
 * @brief Emit a TSO message through the native backend.
 *
 * @param text Message text.
 * @param level Message severity/level.
 * @return 0 on success, or LUZ_E_TSO_MSG on failure.
 */
int lua_tso_msg(const char *text, int level)
{
  (void)level;
  if (text == NULL)
    return LUZ_E_TSO_MSG;
  if (strncmp(text, "LUZ", 3) == 0 && strlen(text) >= 8)
    printf("%s\n", text);
  else
    printf("LUZ30030 %s\n", text);
  return 0;
}

/**
 * @brief Exit the caller with a specified return code.
 *
 * @param rc Return code to propagate.
 * @return rc unchanged.
 */
int lua_tso_exit(int rc)
{
  exit(rc);
  return 0;
}
