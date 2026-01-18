/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO TSO host API stubs.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
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
#include "tso.h"
#include "errors.h"

#include "lua.h"
#include "lauxlib.h"

#include <stdlib.h>

static int l_tso_cmd(lua_State *L)
{
  const char *cmd = luaL_checkstring(L, 1);
  int rc = lua_tso_cmd(cmd);
  if (rc != 0) {
    lua_pushnil(L);
    lua_pushfstring(L, "LUZ30003 tso.cmd not implemented");
    lua_pushinteger(L, rc);
    return 3;
  }
  lua_pushinteger(L, 0);
  return 1;
}

static int l_tso_alloc(lua_State *L)
{
  const char *spec = luaL_checkstring(L, 1);
  int rc = lua_tso_alloc(spec);
  if (rc != 0) {
    lua_pushnil(L);
    lua_pushfstring(L, "LUZ30004 tso.alloc not implemented");
    lua_pushinteger(L, rc);
    return 3;
  }
  lua_pushinteger(L, 0);
  return 1;
}

static int l_tso_free(lua_State *L)
{
  const char *spec = luaL_checkstring(L, 1);
  int rc = lua_tso_free(spec);
  if (rc != 0) {
    lua_pushnil(L);
    lua_pushfstring(L, "LUZ30005 tso.free not implemented");
    lua_pushinteger(L, rc);
    return 3;
  }
  lua_pushinteger(L, 0);
  return 1;
}

static int l_tso_msg(lua_State *L)
{
  const char *text = luaL_checkstring(L, 1);
  int level = (int)luaL_optinteger(L, 2, 0);
  int rc = lua_tso_msg(text, level);
  if (rc != 0) {
    lua_pushnil(L);
    lua_pushfstring(L, "LUZ30024 tso.msg not implemented");
    lua_pushinteger(L, rc);
    return 3;
  }
  lua_pushinteger(L, 0);
  return 1;
}

static int l_tso_exit(lua_State *L)
{
  int code = (int)luaL_optinteger(L, 1, 0);
  int rc = lua_tso_exit(code);
  if (rc != 0) {
    lua_pushnil(L);
    lua_pushfstring(L, "LUZ30025 tso.exit not implemented");
    lua_pushinteger(L, rc);
    return 3;
  }
  lua_pushinteger(L, 0);
  return 1;
}

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

int lua_tso_cmd(const char *cmd)
{
  (void)cmd;
  return LUZ_E_TSO_CMD;
}

int lua_tso_alloc(const char *spec)
{
  (void)spec;
  return LUZ_E_TSO_ALLOC;
}

int lua_tso_free(const char *spec)
{
  (void)spec;
  return LUZ_E_TSO_FREE;
}

int lua_tso_msg(const char *text, int level)
{
  (void)text;
  (void)level;
  return LUZ_E_TSO_MSG;
}

int lua_tso_exit(int rc)
{
  (void)rc;
  return LUZ_E_TSO_EXIT;
}
