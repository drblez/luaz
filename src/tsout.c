/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO TSO module unit test helper for z/OS batch.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | main | function | Validate tso module stub behavior |
 */
#include "lua.h"
#include "lauxlib.h"

#include <stdio.h>
#include <string.h>

extern int luaopen_tso(lua_State *L);

int main(void)
{
  lua_State *L = luaL_newstate();
  const char *msg = NULL;

  if (L == NULL) {
    puts("LUZ00012 TSO UT failed");
    return 8;
  }

  luaL_requiref(L, "tso", luaopen_tso, 1);
  lua_pop(L, 1);

  lua_getglobal(L, "tso");
  lua_getfield(L, -1, "cmd");
  lua_pushstring(L, "LISTCAT");
  if (lua_pcall(L, 1, 3, 0) != LUA_OK) {
    msg = lua_tostring(L, -1);
    if (msg)
      printf("LUZ00012 TSO UT failed: %s\n", msg);
    else
      puts("LUZ00012 TSO UT failed");
    lua_close(L);
    return 8;
  }

  msg = lua_tostring(L, -2);
  if (msg == NULL || strncmp(msg, "LUZ30003", 8) != 0) {
    puts("LUZ00012 TSO UT failed");
    lua_close(L);
    return 8;
  }

  lua_close(L);
  puts("LUZ00011 TSO UT OK");
  return 0;
}
