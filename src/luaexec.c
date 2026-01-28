/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * LUAEXEC entrypoint (stub) for z/OS.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | main | function | Entry point for LUAEXEC |
 * | luaexec_le_handler | function | LE condition handler for abend decode |
 * | luaexec_register_le_handler | function | Register LE condition handler |
 * | luaexec_qdata_abend | type | LE q_data layout for abend conditions |
 * | luaexec_parse_parm | function | Parse PARM tokens for DSN/args |
 * | luaexec_set_args | function | Publish Lua arg table |
 * | luaexec_redirect_luaout | function | Redirect Lua output to LUAOUT DD |
 * | luaexec_close_luaout | function | Close LUAOUT output stream |
 * | luaexec_io_noclose | function | Keep LUAOUT stdout handle open |
 * | luaexec_bind_luaout_stdout | function | Bind io.stdout/io.output to LUAOUT |
 * | luaexec_publish_config | function | Publish LUAZ_CONFIG table |
 * | luaexec_copy_ddname | function | Normalize DDNAME from config |
 * | luaexec_run_line | function | Run LUAEXEC for LUACMD (TSO path) |
 * | lua_tso_luain_load | function | Load LUAIN with VB/FB80 record support |
 *
 * Platform Requirements:
 * - LE: required (C runtime).
 * - AMODE: 31-bit.
 * - EBCDIC: inputs/outputs are EBCDIC in batch.
 * - DDNAME I/O: script input via `DD:LUAIN`.
 */
#include "IODD"
#include "LUA"
#include "LAUXLIB"
#include "LUALIB"
#include "TSO"
#include "POLICY"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <ctype.h>
#include <leawi.h>
#include <ceeedcct.h>
#include <errno.h>

extern int luaopen_tso(lua_State *L);
extern int luaopen_ds(lua_State *L);

typedef struct luaexec_parm {
  const char *dsn;
  const char *mode;
  int args_start;
} luaexec_parm;

/**
 * @brief LE q_data layout for abend conditions (CEE35I).
 */
typedef struct luaexec_qdata_abend {
  uint32_t parm_count;
  uint32_t abend_code;
  uint32_t reason_code;
} luaexec_qdata_abend;

/* Tracks whether the LE handler has been registered for this process. */
static int luaexec_le_handler_registered = 0;
/* Output stream for Lua print redirection. */
static FILE *g_luaout_fp = NULL;

/**
 * @brief LE condition handler to capture abend reason data via CEEGQDT.
 *
 * @param fc Condition token for the active condition.
 * @param token User token supplied when registering the handler.
 * @param result Handler disposition (resume/percolate).
 * @param newfc Optional feedback code for condition promotion.
 */
static void luaexec_le_handler(_FEEDBACK *fc, _INT4 *token, _INT4 *result,
                               _FEEDBACK *newfc)
{
  _FEEDBACK itok = {0};
  _FEEDBACK itok_fc = {0};
  _FEEDBACK dcod_fc = {0};
  _FEEDBACK qdata_fc = {0};
  _INT2 c1 = 0;
  _INT2 c2 = 0;
  _INT2 cond_case = 0;
  _INT2 sev = 0;
  _INT2 control = 0;
  _CHAR3 facid = {'?', '?', '?'};
  _INT4 isi = 0;
  _INT4 qdata_token = 0;
  const luaexec_qdata_abend *qdata = NULL;
  uint32_t abend_word = 0;
  uint32_t reason_word = 0;

  (void)token;
  (void)newfc;

  CEEITOK(&itok, &itok_fc);
  if (_FBCHECK(itok_fc, CEE000) == 0) {
    CEEDCOD(&itok, &c1, &c2, &cond_case, &sev, &control, facid, &isi, &dcod_fc);
  }

  CEEGQDT(fc, &qdata_token, &qdata_fc);
  if (_FBCHECK(qdata_fc, CEE000) == 0 && qdata_token != 0) {
    qdata = (const luaexec_qdata_abend *)((uintptr_t)qdata_token & 0x7FFFFFFF);
    if (qdata != NULL && qdata->parm_count >= 3u) {
      abend_word = qdata->abend_code;
      reason_word = qdata->reason_code;
    }
  }

  printf("LUZ30077 LE abend msg=%d fac=%.3s c1=%d c2=%d case=%d sev=%d "
         "ctrl=%d isi=%d abend=%08X reason=%08X\n",
         fc ? fc->tok_msgno : 0, facid, c1, c2, cond_case, sev, control, isi,
         abend_word, reason_word);

  /* Percolate so LE continues normal abend processing. */
  *result = 20;
}

/**
 * @brief Register the LUAEXEC LE condition handler for abend diagnostics.
 *
 * @return 0 on success, or 8 on failure.
 */
static int luaexec_register_le_handler(void)
{
  _ENTRY routine;
  _INT4 token = 0;
  _FEEDBACK fc = {0};

  if (luaexec_le_handler_registered)
    return 0;

  routine.address = (_POINTER)&luaexec_le_handler;
  routine.nesting = NULL;
  CEEHDLR(&routine, &token, &fc);
  if (_FBCHECK(fc, CEE000) != 0) {
    printf("LUZ30078 CEEHDLR failed msgno=%d\n", fc.tok_msgno);
    return 8;
  }

  luaexec_le_handler_registered = 1;
  return 0;
}

/**
 * @brief Parse LUAEXEC PARM tokens for DSN and MODE flags.
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 * @param out Output structure populated with parsed values.
 */
static void luaexec_parse_parm(int argc, char **argv, luaexec_parm *out)
{
  int i = 0;

  out->dsn = NULL;
  out->mode = NULL;
  out->args_start = argc;
  for (i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--") == 0) {
      out->args_start = i + 1;
      break;
    }
    if (strncmp(argv[i], "DSN=", 4) == 0)
      out->dsn = argv[i] + 4;
    if (strncmp(argv[i], "MODE=", 5) == 0)
      out->mode = argv[i] + 5;
  }
}

/**
 * @brief Publish the Lua "arg" table for the running script.
 *
 * @param L Lua state.
 * @param script Script name or DDNAME string.
 * @param argc Argument count.
 * @param argv Argument vector.
 * @param args_start Index of first user argument.
 */
static void luaexec_set_args(lua_State *L, const char *script, int argc,
                             char **argv, int args_start)
{
  int idx = 1;

  lua_newtable(L);
  lua_pushstring(L, script);
  lua_rawseti(L, -2, 0);
  for (; args_start < argc; args_start++) {
    lua_pushstring(L, argv[args_start]);
    lua_rawseti(L, -2, idx++);
  }
  lua_setglobal(L, "arg");
}

/**
 * @brief Lua C function that writes print output to LUAOUT.
 *
 * @param L Lua state.
 * @return 0 (no Lua return values).
 */
static int luaexec_print_luaout(lua_State *L)
{
  int n = lua_gettop(L);
  int i = 0;

  if (g_luaout_fp == NULL)
    return 0;
  for (i = 1; i <= n; i++) {
    size_t len = 0;
    const char *s = luaL_tolstring(L, i, &len);
    if (i > 1)
      fputc('\t', g_luaout_fp);
    if (s != NULL && len > 0)
      fwrite(s, 1u, len, g_luaout_fp);
    lua_pop(L, 1);
  }
  fputc('\n', g_luaout_fp);
  fflush(g_luaout_fp);
  return 0;
}

/**
 * @brief Normalize a DDNAME value from config or fallback.
 *
 * @param out Output buffer for DDNAME.
 * @param cap Output buffer capacity.
 * @param value Config value (may be NULL).
 * @param fallback Default DDNAME when config is missing.
 * @return None.
 */
static void luaexec_copy_ddname(char *out, size_t cap, const char *value,
                                const char *fallback)
{
  size_t i = 0;
  const char *src = NULL;

  if (out == NULL || cap == 0)
    return;
  src = (value != NULL && value[0] != '\0') ? value : fallback;
  if (src == NULL) {
    out[0] = '\0';
    return;
  }
  if (strlen(src) > 8) {
    out[0] = '\0';
    return;
  }
  for (i = 0; i + 1 < cap && src[i] != '\0' && i < 8; i++)
    out[i] = (char)toupper((unsigned char)src[i]);
  out[i] = '\0';
}

/**
 * @brief Redirect Lua print/output to DDNAME when available.
 *
 * @param L Lua state.
 * @param ddname Output DDNAME (defaults to LUAOUT).
 * @return None.
 */
static void luaexec_redirect_luaout(lua_State *L, const char *ddname)
{
  char path[32];
  const char *use_dd = (ddname != NULL && ddname[0] != '\0') ? ddname
                                                            : "LUAOUT";

  if (L == NULL)
    return;
  if (snprintf(path, sizeof(path), "DD:%s", use_dd) <= 0)
    return;
  g_luaout_fp = fopen(path, "w");
  if (g_luaout_fp == NULL) {
    fprintf(stderr, "LUZ30089 LUAEXEC LUAOUT open failed errno=%d\n", errno);
    return;
  }
  lua_pushcfunction(L, luaexec_print_luaout);
  lua_setglobal(L, "print");
}

/**
 * @brief Keep LUAOUT file handle open when Lua closes stdout.
 *
 * @param L Lua state.
 * @return 2 values: nil and error string (standard file close is blocked).
 */
static int luaexec_io_noclose(lua_State *L)
{
  luaL_Stream *p = (luaL_Stream *)luaL_checkudata(L, 1, LUA_FILEHANDLE);

  p->closef = &luaexec_io_noclose;
  luaL_pushfail(L);
  lua_pushliteral(L, "cannot close standard file");
  return 2;
}

/**
 * @brief Bind Lua io.stdout and io.output to LUAOUT.
 *
 * @param L Lua state.
 * @return None.
 */
static void luaexec_bind_luaout_stdout(lua_State *L)
{
  luaL_Stream *p = NULL;

  if (L == NULL || g_luaout_fp == NULL)
    return;
  p = (luaL_Stream *)lua_newuserdatauv(L, sizeof(luaL_Stream), 0);
  p->f = g_luaout_fp;
  p->closef = &luaexec_io_noclose;
  luaL_setmetatable(L, LUA_FILEHANDLE);

  lua_getglobal(L, "io");
  if (!lua_istable(L, -1)) {
    lua_pop(L, 2);
    return;
  }

  lua_pushvalue(L, -2);
  lua_setfield(L, -2, "stdout");

  lua_getfield(L, -1, "output");
  if (lua_isfunction(L, -1)) {
    lua_pushvalue(L, -3);
    if (lua_pcall(L, 1, 0, 0) != LUA_OK) {
      const char *msg = lua_tostring(L, -1);
      if (msg)
        fprintf(stderr, "LUZ30092 LUAEXEC LUAOUT io.output failed: %s\n", msg);
      else
        fprintf(stderr, "LUZ30092 LUAEXEC LUAOUT io.output failed\n");
      lua_pop(L, 1);
    }
  } else {
    lua_pop(L, 1);
  }

  lua_pop(L, 2);
}

/**
 * @brief Publish LUAZ_CONFIG table based on loaded policy values.
 *
 * @param L Lua state.
 * @return None.
 */
static void luaexec_publish_config(lua_State *L)
{
  int count = 0;
  int i = 0;

  if (L == NULL)
    return;
  count = luaz_policy_key_count();
  lua_newtable(L);
  for (i = 0; i < count; i++) {
    const char *key = luaz_policy_key_name(i);
    const char *value = luaz_policy_value_name(i);
    if (key == NULL || value == NULL)
      continue;
    lua_pushstring(L, value);
    lua_setfield(L, -2, key);
  }
  lua_setglobal(L, "LUAZ_CONFIG");
}

/**
 * @brief Close Lua output stream for LUAOUT redirection.
 *
 * @return None.
 */
static void luaexec_close_luaout(void)
{
  if (g_luaout_fp == NULL)
    return;
  fclose(g_luaout_fp);
  g_luaout_fp = NULL;
}

/**
 * @brief Load Lua chunk from DD:LUAIN with VB/FB80 record support.
 *
 * This loader reads LUAIN using record I/O where possible and builds
 * a newline-delimited buffer so fixed records (FB80) are handled.
 *
 * @param L Lua state.
 * @param script DD:LUAIN path string.
 * @return LUA_OK on success, or a Lua error code on failure.
 */
static int lua_tso_luain_load(lua_State *L, const char *script)
{
  FILE *fp = NULL;
  char path[32];
  char *rec = NULL;
  char *chunk = NULL;
  size_t rec_cap = 32760u;
  size_t chunk_len = 0;
  size_t chunk_cap = 0;
  int rc = LUA_ERRFILE;

  if (script == NULL || script[0] == '\0') {
    lua_pushstring(L, "LUAIN script path is empty");
    return LUA_ERRFILE;
  }
  if (snprintf(path, sizeof(path), "%s", script) <= 0) {
    lua_pushstring(L, "LUAIN script path format failed");
    return LUA_ERRFILE;
  }

  /* Change note: add LUAIN record loader for FB80/VB support.
   * Problem: luaL_loadfile on DD:LUAIN is byte-stream oriented and does not
   * reliably handle fixed-length records supplied by JCL (FB80).
   * Expected effect: build a newline-delimited buffer using record I/O so
   * LUAIN works for VB and FB80 datasets.
   * Impact: LUAEXEC loads from DD:LUAIN using fread record I/O when possible.
   * Ref: src/luaexec.md#luain-record-io
   */
  fp = fopen(path, "rb,type=record");
  if (fp == NULL)
    fp = fopen(path, "rb,recfm=FB,lrecl=80");
  if (fp == NULL)
    return luaL_loadfile(L, path);

  rec = (char *)malloc(rec_cap);
  if (rec == NULL) {
    fclose(fp);
    lua_pushstring(L, "LUAIN record buffer alloc failed");
    return LUA_ERRMEM;
  }

  while (1) {
    size_t n = fread(rec, 1u, rec_cap, fp);
    if (n == 0) {
      if (ferror(fp)) {
        rc = LUA_ERRFILE;
        lua_pushstring(L, "LUAIN record read failed");
        goto cleanup;
      }
      break;
    }
    while (n > 0 &&
           (rec[n - 1] == ' ' || rec[n - 1] == '\0' ||
            rec[n - 1] == '\r' || rec[n - 1] == '\n')) {
      n--;
    }
    if (chunk_len + n + 1u > chunk_cap) {
      size_t new_cap = chunk_cap ? chunk_cap * 2u : 1024u;
      while (new_cap < chunk_len + n + 1u)
        new_cap *= 2u;
      chunk = (char *)realloc(chunk, new_cap);
      if (chunk == NULL) {
        rc = LUA_ERRMEM;
        lua_pushstring(L, "LUAIN chunk alloc failed");
        goto cleanup;
      }
      chunk_cap = new_cap;
    }
    if (n > 0) {
      memcpy(chunk + chunk_len, rec, n);
      chunk_len += n;
    }
    chunk[chunk_len++] = '\n';
  }

  if (chunk_len == 0) {
    rc = luaL_loadbuffer(L, "", 0, path);
  } else {
    rc = luaL_loadbuffer(L, chunk, chunk_len, path);
  }

cleanup:
  free(chunk);
  free(rec);
  fclose(fp);
  return rc;
}

/**
 * @brief Execute a Lua script with Lua/TSO runtime initialization.
 *
 * The MODE=PARM token, if present, overrides the default mode argument.
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 * @param mode Default execution mode string (TSO/PGM).
 * @return 0 on success, or 8 on failure (LUZNNNNN-prefixed diagnostics emitted).
 *
 * Change note: align prefix format to LUZNNNNN.
 * Problem: prior wording used LUZNNNNN formatting inconsistently in docs.
 * Expected effect: documentation matches emitted message format.
 * Impact: comment-only change; no runtime behavior is altered.
 */
static int luaexec_run(int argc, char **argv, const char *mode)
{
  luaexec_parm parm;
  const char *script = NULL;
  const char *run_mode = mode;
  const char *cfg_luain = NULL;
  const char *cfg_luaout = NULL;
  char luain_ddname[9];
  char luaout_ddname[9];
  char luain_path[32];
  lua_State *L = NULL;
  luaexec_parse_parm(argc, argv, &parm);
  if (parm.dsn != NULL && parm.dsn[0] != '\0') {
    puts("LUZ30041 LUAEXEC DSN in PARM not implemented");
    return 8;
  }
  if (parm.mode != NULL && parm.mode[0] != '\0')
    run_mode = parm.mode;
  if (run_mode == NULL)
    run_mode = "PGM";
  /* Change note: remove LUAEXEC mode debug output.
   * Problem: verbose SYSOUT in normal runs.
   * Expected effect: reduce diagnostic noise without changing behavior.
   * Impact: no mode/args_start printout during LUAEXEC.
   */

  /* Change note: load LUACFG before Lua state creation.
   * Problem: runtime policy and DD overrides were unavailable at startup.
   * Expected effect: policy values can affect LUAIN/LUAOUT and TSO defaults.
   * Impact: LUACFG parsing happens once per LUAEXEC run.
   */
  luaz_policy_load("DD:LUACFG");
  cfg_luain = luaz_policy_get_raw("luain.dd");
  cfg_luaout = luaz_policy_get_raw("luaout.dd");
  luaexec_copy_ddname(luain_ddname, sizeof(luain_ddname), cfg_luain, "LUAIN");
  luaexec_copy_ddname(luaout_ddname, sizeof(luaout_ddname), cfg_luaout,
                      "LUAOUT");
  if (luain_ddname[0] == '\0') {
    strcpy(luain_ddname, "LUAIN");
  }
  if (snprintf(luain_path, sizeof(luain_path), "DD:%s", luain_ddname) > 0)
    script = luain_path;
  else
    script = "DD:LUAIN";

  L = luaL_newstate();
  if (L == NULL) {
    puts("LUZ30040 LUAEXEC init failed");
    return 8;
  }
  if (luaz_io_dd_register() != 0) {
    puts("LUZ30044 LUAEXEC dd register failed");
    lua_close(L);
    return 8;
  }

  luaL_openlibs(L);
  luaL_requiref(L, "tso", luaopen_tso, 1);
  lua_pop(L, 1);
  /* Change note: preload ds module for DDNAME dataset I/O.
   * Problem: ds.open_dd was unavailable in Lua runtime.
   * Expected effect: Lua can open DDNAME streams via ds.open_dd.
   * Impact: ds module is available through package.preload.
   */
  luaL_requiref(L, "ds", luaopen_ds, 1);
  lua_pop(L, 1);
  lua_pushstring(L, run_mode);
  lua_setglobal(L, "LUAZ_MODE");
  luaexec_publish_config(L);

  luaexec_set_args(L, script, argc, argv, parm.args_start);
  /* Change note: direct Lua output to LUAOUT DDNAME.
   * Problem: Lua output and debug output were mixed in SYSTSPRT.
   * Expected effect: Lua stdout (print/io) routes to LUAOUT when allocated.
   * Impact: debug output remains on SYSTSPRT; Lua output is separated.
   */
  luaexec_redirect_luaout(L, luaout_ddname);
  luaexec_bind_luaout_stdout(L);

  if (lua_tso_luain_load(L, script) != LUA_OK) {
    const char *msg = lua_tostring(L, -1);
    if (msg)
      printf("LUZ30042 LUAEXEC load failed: %s\n", msg);
    else
      puts("LUZ30042 LUAEXEC load failed");
    luaexec_close_luaout();
    lua_close(L);
    return 8;
  }

  if (lua_pcall(L, 0, LUA_MULTRET, 0) != LUA_OK) {
    const char *msg = lua_tostring(L, -1);
    if (msg)
      printf("LUZ30043 LUAEXEC run failed: %s\n", msg);
    else
      puts("LUZ30043 LUAEXEC run failed");
    luaexec_close_luaout();
    lua_close(L);
    return 8;
  }

  if (lua_gettop(L) > 0 && lua_isinteger(L, -1)) {
    int rc = (int)lua_tointeger(L, -1);
    luaexec_close_luaout();
    lua_close(L);
    return rc;
  }

  /* Change note: close LUAOUT stream after Lua completes.
   * Problem: LUAOUT file handle remained open after script end.
   * Expected effect: ensure output is flushed and resources released.
   * Impact: closes LUAOUT even when no capture errors occur.
   */
  luaexec_close_luaout();
  lua_close(L);
  return 0;
}

/**
 * @brief Tokenize a command line into argv tokens for LUAEXEC.
 *
 * @param line Input command line buffer (EBCDIC).
 * @param line_len Length of the input line.
 * @param buf Output buffer to hold a mutable copy of the line.
 * @param cap Capacity of the output buffer in bytes.
 * @param argv Output argv array.
 * @param max_argv Capacity of the argv array.
 * @return Argument count on success, or -1 on failure.
 */
static int luaexec_tokenize(const char *line, int line_len, char *buf,
                            size_t cap, char **argv, int max_argv)
{
  int argc = 1;
  int len = line_len;
  char *p = NULL;

  if (buf == NULL || argv == NULL || max_argv < 2)
    return -1;

  argv[0] = "LUAEXEC";
  if (line == NULL || line_len <= 0) {
    argv[1] = NULL;
    return argc;
  }

  /* Change note: emit raw ASM->C line only in debug mode.
   * Problem: raw line diagnostics clutter SYSOUT in normal runs.
   * Expected effect: trace.level controls LUZ30073 emission.
   * Impact: LUZ30073 appears only when trace.level=debug.
   */
  if (luaz_policy_trace_enabled("debug")) {
    printf("LUZ30073 LUAEXRUN parse line len=%d text='%.*s'\n",
           line_len, line_len, line);
  }

  if ((size_t)len >= cap)
    len = (int)cap - 1;
  memcpy(buf, line, (size_t)len);
  buf[len] = '\0';
  p = buf;
  while (*p != '\0') {
    while (*p == ' ')
      p++;
    if (*p == '\0')
      break;
    if (argc + 1 >= max_argv)
      break;
    if (*p == '\'') {
      p++;
      argv[argc++] = p;
      while (*p != '\0' && *p != '\'')
        p++;
      if (*p == '\'')
        *p++ = '\0';
      continue;
    }
    argv[argc++] = p;
    while (*p != '\0' && *p != ' ')
      p++;
    if (*p == ' ')
      *p++ = '\0';
  }
  argv[argc] = NULL;
  return argc;
}

#pragma linkage(luaexec_run_line, OS)
#pragma export(luaexec_run_line)
#pragma map(luaexec_run_line, "LUAEXRUN")
/**
 * @brief Run LUAEXEC from a single command line (TSO command processor path).
 *
 * Mandatory requirement: LUACMD must pass MODE=TSO explicitly and
 * LUAEXRUN must not default to TSO. Mode is determined only by params.
 *
 * @param line Pointer to the command line text (may include MODE= and --).
 * @param line_len Length of the command line text.
 * @param cppl CPPL pointer from LUACMD (address parameter).
 * @return 0 on success, or 8 on validation/execution failure.
 */
int luaexec_run_line(const char *line, int line_len, void *cppl)
{
  char buf[512];
  char *argv[64];
  int argc = 0;

  /* Change note: register LE condition handler before any parsing.
   * Problem: ABEND 4088/63 occurs before luaexec_run, so handler is missed.
   * Expected effect: handler captures q_data for early LUACMD/LUAEXRUN abends.
   * Impact: LUAEXRUN emits LUZ30077 on LE abends before tokenization.
   * Ref: src/luaexec.md#le-condition-handler
   */
  luaexec_register_le_handler();

  if (line == NULL) {
    puts("LUZ30054 LUAEXRUN line pointer is NULL");
    return 8;
  }
  if (line_len < 0 || line_len > 511) {
    puts("LUZ30053 LUAEXRUN invalid line length");
    return 8;
  }
  /* Change note: load LUACFG early for trace-level diagnostics.
   * Problem: trace.level was unavailable before tokenization logs.
   * Expected effect: LUZ30072/30073 honor trace.level in LUACFG.
   * Impact: debug diagnostics appear only when trace.level=debug.
   */
  if (!luaz_policy_loaded())
    luaz_policy_load("DD:LUACFG");
  /* Change note: cache LUACMD CPPL for IKJEFTSR optional parameters.
   * Problem: CPPL from LUACMD was ignored, preventing param8 usage.
   * Expected effect: LUAEXRUN forwards CPPL to TSO command execution.
   * Impact: tso.cmd can use IKJEFTSR param8 when CPPL is available.
   * Ref: src/luaexec.c.md#cppl-forwarding
   */
  lua_tso_set_cppl_cmd(cppl);
  /* Change note: gate LUAEXRUN address diagnostics by trace.level.
   * Problem: unconditional debug output clutters SYSOUT.
   * Expected effect: trace.level controls LUZ30072 emission.
   * Impact: LUZ30072 appears only when trace.level=debug.
   */
  if (luaz_policy_trace_enabled("debug")) {
    printf("LUZ30072 LUAEXRUN dbg line=%08X len=%d buf=%08X argv=%08X\n",
           (unsigned int)(uintptr_t)line, line_len,
           (unsigned int)(uintptr_t)buf, (unsigned int)(uintptr_t)argv);
  }

  /* Change note: remove LUAEXRUN entry/raw-line debug output.
   * Problem: debug prints clutter SYSOUT in normal runs.
   * Expected effect: only standard LUZ messages remain; parsing unchanged.
   * Impact: reduces stdout noise for LUAEXRUN path.
   */

  argc = luaexec_tokenize(line, line_len, buf, sizeof(buf), argv,
                          (int)(sizeof(argv) / sizeof(argv[0])));
  if (argc < 0)
    return 8;
  /* Change note: remove LUAEXRUN argv token debug output.
   * Problem: verbose SYSOUT in normal runs.
   * Expected effect: reduce diagnostic noise without changing behavior.
   * Impact: no argc/argv prints during LUAEXRUN.
   */
  /* Change note: restore PGM default for LUAEXRUN.
   * Problem: defaulting to TSO violates the contract that LUACMD must
   * pass MODE=TSO explicitly; RC=12 persists after LUACMD returns.
   * Expected effect: LUAZ_MODE follows MODE= tokens consistently.
   */
  {
    return luaexec_run(argc, argv, "PGM");
  }
}

/**
 * @brief LUAEXEC program entry point (PGM mode).
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 * @return 0 on success, or 8 on failure.
 */
int main(int argc, char **argv)
{
  /* Change note: register LE condition handler in PGM entry.
   * Problem: PGM-mode abends lack LE q_data context in SYSPRINT.
   * Expected effect: handler captures abend/reason for main entry too.
   * Impact: LUZ30077 emitted on LE abends in PGM mode.
   * Ref: src/luaexec.md#le-condition-handler
   */
  luaexec_register_le_handler();

  return luaexec_run(argc, argv, "PGM");
}
