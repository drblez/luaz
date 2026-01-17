/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO ISPF API stubs.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | lua_ispf_qry | function | Query ISPF environment |
 * | lua_ispf_exec | function | Execute ISPF command |
 */
#include "ISPF"
#include "ERRORS"

int lua_ispf_qry(void)
{
  return LUZ_E_ISPF_QRY;
}

int lua_ispf_exec(const char *cmdline)
{
  (void)cmdline;
  return LUZ_E_ISPF_EXEC;
}
