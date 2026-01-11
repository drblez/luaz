/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO TSO host API stubs.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | lua_tso_cmd | function | Execute a TSO command |
 * | lua_tso_alloc | function | Allocate a dataset |
 * | lua_tso_free | function | Free a dataset allocation |
 */
#include "luaz_tso.h"

int lua_tso_cmd(const char *cmd)
{
  (void)cmd;
  return -1; /* LUZ-30003 tso.cmd not implemented */
}

int lua_tso_alloc(const char *spec)
{
  (void)spec;
  return -1; /* LUZ-30004 tso.alloc not implemented */
}

int lua_tso_free(const char *spec)
{
  (void)spec;
  return -1; /* LUZ-30005 tso.free not implemented */
}
