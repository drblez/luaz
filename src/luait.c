/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO integration test runner for batch mode.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | main | function | Execute Lua script from LUAIN DD |
 */
#include "iodd.h"

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include <stdio.h>

extern int luaopen_tso(lua_State *L);

int main(void)
{
  lua_State *L = luaL_newstate();
  int rc = 0;
  const char *msg = NULL;

  if (L == NULL) {
    puts("LUZ00021 Lua IT init failed");
    return 8;
  }
  if (luaz_io_dd_register() != 0) {
    puts("LUZ00021 Lua IT dd register failed");
    lua_close(L);
    return 8;
  }

  luaL_openlibs(L);
  luaL_requiref(L, "tso", luaopen_tso, 1);
  lua_pop(L, 1);

  if (luaL_loadfile(L, "DD:LUAIN") != LUA_OK) {
    msg = lua_tostring(L, -1);
    if (msg)
      printf("LUZ00021 Lua IT load failed: %s\n", msg);
    else
      puts("LUZ00021 Lua IT load failed");
    lua_close(L);
    return 8;
  }

  if (lua_pcall(L, 0, LUA_MULTRET, 0) != LUA_OK) {
    msg = lua_tostring(L, -1);
    if (msg)
      printf("LUZ00021 Lua IT run failed: %s\n", msg);
    else
      puts("LUZ00021 Lua IT run failed");
    lua_close(L);
    return 8;
  }

  if (lua_gettop(L) > 0 && lua_isinteger(L, -1))
    rc = (int)lua_tointeger(L, -1);
  lua_close(L);
  return rc;
}
