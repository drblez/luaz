/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO TSO host API stubs.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | read_dd_to_lines | function | Read DDNAME output into Lua table |
 * | tso_call_rexx | function | Invoke LUTSO REXX exec via IRXEXEC |
 * | l_tso_cmd | function | Lua wrapper for tso.cmd |
 * | l_tso_alloc | function | Lua wrapper for tso.alloc |
 * | l_tso_free | function | Lua wrapper for tso.free |
 * | l_tso_msg | function | Lua wrapper for tso.msg |
 * | l_tso_exit | function | Lua wrapper for tso.exit |
 * | lua_tso_cmd | function | Execute a TSO command |
 * | lua_tso_alloc | function | Allocate a dataset |
 * | lua_tso_free | function | Free a dataset allocation |
 * | lua_tso_msg | function | Emit a TSO message |
 * | lua_tso_exit | function | Exit with RC |
 * | luaopen_tso | function | Lua module entrypoint |
 */
#include "TSO"
#include "ERRORS"
#include "TSONATV"

#include "LUA"
#include "LAUXLIB"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

/* IKJTSOEV function signature for environment probing. */
typedef void (*ikjtsoev_fn)(int *, int *, int *, int *, void **);
/* Forward declaration for IRXEXEC parameter block. */
typedef struct IRXEXEC_type IRXEXEC_type;
#pragma linkage(fetch, OS)
/* LE service resolver for dynamic entry points (IKJTSOEV/IRXEXEC). */
extern void (*fetch(const char *name))();
typedef int (*irxexec_fn)();
static int g_last_irx_rc = 0; /* Last IRXEXEC return code. */
static int g_last_rexx_rc = 0; /* Last REXX return code. */
static int g_cppl_addr = 0; /* Cached CPPL address (31-bit). */


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

  ikjtsoev = (ikjtsoev_fn)fetch("IKJTSOEV");
  if (ikjtsoev == NULL) {
    env_state = -1;
    g_last_irx_rc = -2;
    g_last_rexx_rc = 0;
    return -1;
  }

  ikjtsoev(&parm1, &rc, &reason, &abend, &cppl);
  if (rc == 0) {
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
  FILE *fp;
  char buf[2048];
  char *rec = NULL;
  size_t rec_cap = 32760u;
  int record_io = 0;
  int idx = 0;

  if (ddname == NULL || ddname[0] == '\0')
    return 0;
  if (snprintf(path, sizeof(path), "DD:%s", ddname) <= 0)
    return 0;
  /* Change note: prefer record I/O for DD output capture.
   * Problem: stream I/O can mis-handle fixed record datasets (FB/VB).
   * Expected effect: read records via fread and normalize line endings.
   * Impact: tso.cmd output works for FB/VB SYSTSPRT datasets.
   * Ref: src/tso.md#read-dd-record-io
   */
  fp = fopen(path, "rb,type=record");
  if (fp != NULL) {
    record_io = 1;
  } else {
    fp = fopen(path, "rb");
  }
  if (fp == NULL)
    return 0;

  lua_newtable(L);
  if (record_io) {
    rec = (char *)malloc(rec_cap);
    if (rec == NULL) {
      fclose(fp);
      return 0;
    }
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
      size_t len = strcspn(buf, "\r\n");
      lua_pushstring(L, "LUZ30031 ");
      lua_pushlstring(L, buf, len);
      lua_concat(L, 2);
      lua_rawseti(L, -2, ++idx);
    }
  }
  fclose(fp);
  return 1;
}

/**
 * @brief Invoke the LUTSO REXX exec via IRXEXEC for TSO command processing.
 *
 * REXX path is legacy/compatibility only. Do not modify or extend
 * REXX-based execution unless explicitly requested; direct TSO is the
 * active development path.
 *
 * Change note: record REXX restriction near the REXX entry point.
 * Problem: REXX path must not be modified without approval.
 * Expected effect: contributors avoid changes to REXX fallback.
 * Impact: documents policy; runtime behavior unchanged.
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
  char native_dd[9];
  int native_reason = 0;
  int native_abend = 0;
  int native_dair_rc = 0;
  int native_cat_rc = 0;
  int native_rc = LUZ_E_TSO_CMD;

  lua_getglobal(L, "LUAZ_MODE");
  if (!lua_isstring(L, -1) || strcmp(lua_tostring(L, -1), "TSO") != 0) {
    lua_pop(L, 1);
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30045 tso.cmd not available in PGM mode");
    lua_pushinteger(L, LUZ_E_TSO_CMD);
    return 3;
  }
  lua_pop(L, 1);

  /* Change note: ignore outdd option in direct TSO path.
   * Problem: native TSOCMD always uses internal DDNAME capture.
   * Expected effect: callers do not expect outdd to be honored here.
   * Impact: outdd from Lua is ignored when using native path.
   */

  /* Change note: enforce direct TSO path (no REXX fallback).
   * Problem: REXX execution is out of scope without explicit approval.
   * Expected effect: tso.cmd uses native IKJEFTSR path only.
   * Impact: tso.cmd returns an error if native TSO is unavailable.
   */
  if (tso_native_env_init() != 0) {
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30047 tso.cmd native TSO unavailable");
    lua_pushinteger(L, LUZ_E_TSO_CMD);
    return 3;
  }

  native_dd[0] = '\0';
  native_rc = tso_native_cmd_cp(cmd, native_dd, sizeof(native_dd),
                                &native_reason, &native_abend,
                                &native_dair_rc, &native_cat_rc);
  if (native_rc != LUZ_E_TSO_CMD) {
    lua_pushinteger(L, native_rc);
    if (read_dd_to_lines(L, native_dd)) {
      tso_native_cmd_cleanup(native_dd);
      return 2;
    }
    tso_native_cmd_cleanup(native_dd);
    lua_newtable(L);
    return 2;
  }
  if (native_dd[0] != '\0')
    tso_native_cmd_cleanup(native_dd);
  lua_pushnil(L);
  lua_pushfstring(L,
                  "LUZ30032 tso.cmd failed native reason=%d abend=%d"
                  " dair_rc=%d cat_rc=%d",
                  native_reason, native_abend, native_dair_rc, native_cat_rc);
  lua_pushinteger(L, LUZ_E_TSO_CMD);
  return 3;
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
  char native_dd[9];
  int native_reason = 0;
  int native_abend = 0;
  int native_dair_rc = 0;
  int native_cat_rc = 0;
  int native_rc = LUZ_E_TSO_CMD;
  if (cmd == NULL)
    return LUZ_E_TSO_CMD;
  /* Change note: enforce direct TSO path for C API (no REXX).
   * Problem: REXX execution is out of scope without explicit approval.
   * Expected effect: C API mirrors native IKJEFTSR path.
   * Impact: returns LUZ_E_TSO_CMD when native env is unavailable.
   */
  if (tso_native_env_init() != 0)
    return LUZ_E_TSO_CMD;
  native_dd[0] = '\0';
  native_rc = tso_native_cmd_cp(cmd, native_dd, sizeof(native_dd),
                                &native_reason, &native_abend,
                                &native_dair_rc, &native_cat_rc);
  if (native_dd[0] != '\0')
    tso_native_cmd_cleanup(native_dd);
  return native_rc;
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
