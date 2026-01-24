/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO integration test runner for batch mode.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | main | function | Execute Lua script from LUAIN DD |
 * | lua_tso_luain_load | function | Load LUAIN with VB/FB80 record support |
 */
#include "IODD"

#include "LUA"
#include "LAUXLIB"
#include "LUALIB"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int luaopen_tso(lua_State *L);

/**
 * @brief Load Lua chunk from DD:LUAIN with VB/FB80 record support.
 *
 * This loader reads LUAIN using record I/O where possible and builds
 * a newline-delimited buffer so fixed records (FB80) are handled.
 *
 * @param L Lua state.
 * @return LUA_OK on success, or a Lua error code on failure.
 */
static int lua_tso_luain_load(lua_State *L)
{
  FILE *fp = NULL;
  char *rec = NULL;
  char *chunk = NULL;
  size_t rec_cap = 32760u;
  size_t chunk_len = 0;
  size_t chunk_cap = 0;
  int rc = LUA_ERRFILE;

  /* Change note: add LUAIN record loader for FB80/VB support.
   * Problem: luaL_loadfile on DD:LUAIN is byte-stream oriented and does not
   * reliably handle fixed-length records supplied by JCL (FB80).
   * Expected effect: build a newline-delimited buffer using record I/O so
   * LUAIN works for VB and FB80 datasets.
   * Impact: LUAIN load works for fixed-record tests without code changes.
   * Ref: src/luait.md#luain-record-io
   */
  fp = fopen("DD:LUAIN", "rb,type=record");
  if (fp == NULL)
    fp = fopen("DD:LUAIN", "rb,recfm=FB,lrecl=80");
  if (fp == NULL)
    return luaL_loadfile(L, "DD:LUAIN");

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
    rc = luaL_loadbuffer(L, "", 0, "DD:LUAIN");
  } else {
    rc = luaL_loadbuffer(L, chunk, chunk_len, "DD:LUAIN");
  }

cleanup:
  free(chunk);
  free(rec);
  fclose(fp);
  return rc;
}

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

  if (lua_tso_luain_load(L) != LUA_OK) {
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
