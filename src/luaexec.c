/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * LUAEXEC entrypoint (stub) for z/OS.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | main | function | Entry point for LUAEXEC |
 * | luaexec_parse_parm | function | Parse PARM tokens for DSN/args |
 * | luaexec_set_args | function | Publish Lua arg table |
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int luaopen_tso(lua_State *L);

typedef struct luaexec_parm {
  const char *dsn;
  const char *mode;
  int args_start;
} luaexec_parm;

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
 * @return 0 on success, or 8 on failure (LUZ-prefixed diagnostics emitted).
 */
static int luaexec_run(int argc, char **argv, const char *mode)
{
  luaexec_parm parm;
  const char *script = "DD:LUAIN";
  const char *run_mode = mode;
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
  lua_pushstring(L, run_mode);
  lua_setglobal(L, "LUAZ_MODE");

  luaexec_set_args(L, script, argc, argv, parm.args_start);

  if (lua_tso_luain_load(L, script) != LUA_OK) {
    const char *msg = lua_tostring(L, -1);
    if (msg)
      printf("LUZ30042 LUAEXEC load failed: %s\n", msg);
    else
      puts("LUZ30042 LUAEXEC load failed");
    lua_close(L);
    return 8;
  }

  if (lua_pcall(L, 0, LUA_MULTRET, 0) != LUA_OK) {
    const char *msg = lua_tostring(L, -1);
    if (msg)
      printf("LUZ30043 LUAEXEC run failed: %s\n", msg);
    else
      puts("LUZ30043 LUAEXEC run failed");
    lua_close(L);
    return 8;
  }

  if (lua_gettop(L) > 0 && lua_isinteger(L, -1)) {
    int rc = (int)lua_tointeger(L, -1);
    lua_close(L);
    return rc;
  }

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
 * @return 0 on success, or 8 on validation/execution failure.
 */
int luaexec_run_line(const char *line, int line_len)
{
  char buf[512];
  char *argv[64];
  int argc = 0;

  if (line == NULL) {
    puts("LUZ30054 LUAEXRUN line pointer is NULL");
    return 8;
  }
  if (line_len < 0 || line_len > 511) {
    puts("LUZ30053 LUAEXRUN invalid line length");
    return 8;
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
  return luaexec_run(argc, argv, "PGM");
}
