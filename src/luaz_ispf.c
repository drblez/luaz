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
#include "luaz_ispf.h"

int lua_ispf_qry(void)
{
  return -1; /* LUZ-30010 ispf.qry not implemented */
}

int lua_ispf_exec(const char *cmdline)
{
  (void)cmdline;
  return -1; /* LUZ-30011 ispf.exec not implemented */
}
