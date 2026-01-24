/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO loadfile unit test helper for z/OS batch.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | main | function | Validate luaL_loadfile via LUAPATH |
 */
#include "IODD"

#include "LUA"
#include "LAUXLIB"

#include <stdio.h>

int main(void)
{
  lua_State *L;
  int rc;

  if (luaz_io_dd_register() != 0) {
    puts("LUZ00010 loadfile UT register failed");
    return 8;
  }

  L = luaL_newstate();
  if (L == NULL) {
    puts("LUZ00010 loadfile UT state failed");
    return 8;
  }

  rc = luaL_loadfile(L, "SHORT");
  if (rc != LUA_OK) {
    const char *msg = lua_tostring(L, -1);
    if (msg != NULL)
      printf("LUZ00010 loadfile UT failed: %s\n", msg);
    else
      puts("LUZ00010 loadfile UT failed");
    lua_close(L);
    return 8;
  }

  lua_close(L);
  puts("LUZ00009 loadfile UT OK");
  return 0;
}
