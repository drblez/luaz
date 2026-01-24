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
#include "LUA"
#include "LAUXLIB"

#include <stdio.h>
#include <string.h>

extern int luaopen_tso(lua_State *L);

int main(void)
{
  lua_State *L = luaL_newstate();
  const char *msg = NULL;

  puts("LUZ00017 TSOUT start");
  fflush(NULL);

  if (L == NULL) {
    puts("LUZ00012 TSO UT failed");
    return 8;
  }

 luaL_requiref(L, "tso", luaopen_tso, 1);
  lua_pop(L, 1);

  lua_getglobal(L, "tso");
  lua_getfield(L, -1, "cmd");
  lua_pushstring(L, "LISTCAT LEVEL(DRBLEZ.LUA)");
  lua_newtable(L);
  lua_pushstring(L, "TSOOUT");
  lua_setfield(L, -2, "outdd");
  if (lua_pcall(L, 2, 2, 0) != LUA_OK) {
    msg = lua_tostring(L, -1);
    if (msg)
      printf("LUZ00012 TSO UT failed: %s\n", msg);
    else
      puts("LUZ00012 TSO UT failed");
    lua_close(L);
    return 8;
  }

  if (!lua_isinteger(L, -2)) {
    msg = lua_tostring(L, -1);
    if (msg)
      printf("LUZ00012 TSO UT failed: %s\n", msg);
    else
      puts("LUZ00012 TSO UT failed: rc not integer");
    lua_close(L);
    return 8;
  }
  if (!lua_istable(L, -1)) {
    puts("LUZ00012 TSO UT failed: output not table");
    lua_close(L);
    return 8;
  }
  if (lua_rawlen(L, -1) == 0) {
    puts("LUZ00012 TSO UT failed: output empty");
    lua_close(L);
    return 8;
  }
  if (lua_tointeger(L, -2) != 0) {
    printf("LUZ00012 TSO UT failed: rc=%d\n", (int)lua_tointeger(L, -2));
    lua_close(L);
    return 8;
  }
  lua_rawgeti(L, -1, 1);
  msg = lua_tostring(L, -1);
  lua_pop(L, 1);
  if (msg == NULL || strncmp(msg, "LUZ30031", 8) != 0) {
    printf("LUZ00012 TSO UT failed: line1=%s\n", msg ? msg : "(null)");
    lua_close(L);
    return 8;
  }

  lua_pop(L, 2);
  lua_getglobal(L, "tso");
  lua_getfield(L, -1, "msg");
  lua_pushstring(L, "LUZ00011 TSO UT OK");
  if (lua_pcall(L, 1, 1, 0) != LUA_OK) {
    msg = lua_tostring(L, -1);
    if (msg)
      printf("LUZ00012 TSO UT failed: %s\n", msg);
    else
      puts("LUZ00012 TSO UT failed");
    lua_close(L);
    return 8;
  }

  lua_close(L);
  return 0;
}
