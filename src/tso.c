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
#include "tso.h"
#include "errors.h"

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
