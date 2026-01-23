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
 *
 * Platform Requirements:
 * - LE: required (C runtime).
 * - AMODE: 31-bit.
 * - EBCDIC: inputs/outputs are EBCDIC in batch.
 * - DDNAME I/O: script input via `DD:LUAIN`.
 */
#include "iodd.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include <stdio.h>
#include <string.h>

extern int luaopen_tso(lua_State *L);

typedef struct luaexec_parm {
  const char *dsn;
  const char *mode;
  int args_start;
  int bad_mode;
} luaexec_parm;

/**
 * @brief Parse LUAEXEC PARM tokens for MODE and DSN flags.
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 * @param out Output structure populated with parsed values.
 * @param forced_mode Optional forced MODE (overrides user input when non-NULL).
 */
static void luaexec_parse_parm(int argc, char **argv, luaexec_parm *out,
                               const char *forced_mode)
{
  int i = 0;

  out->dsn = NULL;
  out->mode = forced_mode ? forced_mode : "PGM";
  out->args_start = argc;
  out->bad_mode = 0;
  for (i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--") == 0) {
      out->args_start = i + 1;
      break;
    }
    if (strncmp(argv[i], "MODE=", 5) == 0) {
      const char *mode = argv[i] + 5;
      if (strcmp(mode, "TSO") == 0 || strcmp(mode, "PGM") == 0) {
        if (forced_mode != NULL && strcmp(mode, forced_mode) != 0)
          out->bad_mode = 1;
        else
          out->mode = mode;
      } else {
        out->bad_mode = 1;
      }
      continue;
    }
    if (strncmp(argv[i], "DSN=", 4) == 0)
      out->dsn = argv[i] + 4;
  }

  if (forced_mode != NULL)
    out->mode = forced_mode;
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
 * @brief Execute a Lua script with Lua/TSO runtime initialization.
 *
 * @param argc Argument count.
 * @param argv Argument vector.
 * @param forced_mode Optional forced MODE (TSO/PGM).
 * @return 0 on success, or 8 on failure (LUZ-prefixed diagnostics emitted).
 */
static int luaexec_run(int argc, char **argv, const char *forced_mode)
{
  luaexec_parm parm;
  const char *script = "DD:LUAIN";
  lua_State *L = NULL;
  luaexec_parse_parm(argc, argv, &parm, forced_mode);
  if (parm.bad_mode) {
    puts("LUZ30046 LUAEXEC invalid MODE in PARM");
    return 8;
  }
  if (parm.dsn != NULL && parm.dsn[0] != '\0') {
    puts("LUZ30041 LUAEXEC DSN in PARM not implemented");
    return 8;
  }

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
  lua_pushstring(L, parm.mode);
  lua_setglobal(L, "LUAZ_MODE");

  luaexec_set_args(L, script, argc, argv, parm.args_start);

  if (luaL_loadfile(L, script) != LUA_OK) {
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
 * @param line Pointer to the command line text.
 * @param line_len Length of the command line text.
 * @param forced_mode Optional forced MODE (TSO/PGM).
 * @return 0 on success, or 8 on validation/execution failure.
 */
int luaexec_run_line(const char *line, int line_len, const char *forced_mode)
{
  char buf[512];
  char *argv[64];
  const char *mode = "TSO";
  int argc = 0;

  if (forced_mode != NULL && forced_mode[0] != '\0')
    mode = forced_mode;

  if (line == NULL) {
    puts("LUZ30054 LUAEXRUN line pointer is NULL");
    return 8;
  }
  if (line_len < 0 || line_len > 511) {
    puts("LUZ30053 LUAEXRUN invalid line length");
    return 8;
  }

  puts("LUZ30049 LUAEXRUN entry");
  fflush(stdout);

  argc = luaexec_tokenize(line, line_len, buf, sizeof(buf), argv,
                          (int)(sizeof(argv) / sizeof(argv[0])));
  if (argc < 0)
    return 8;
  return luaexec_run(argc, argv, mode);
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
  return luaexec_run(argc, argv, NULL);
}
