/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO LUAPATH lookup and load stubs.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | luaz_path_lookup | function | Map long module name to member via LUAMAP |
 * | luaz_path_load | function | Load module source from LUAPATH |
 */
#include "luaz_errors.h"
#include "luaz_path.h"

int luaz_path_lookup(const char *modname, char *member, unsigned long *len)
{
  (void)modname;
  (void)member;
  if (len) {
    *len = 0;
  }
  return LUZ_E_PATH_LOOKUP;
}

int luaz_path_load(const char *modname, const char *member,
                   char *buf, unsigned long *len)
{
  (void)modname;
  (void)member;
  (void)buf;
  if (len) {
    *len = 0;
  }
  return LUZ_E_PATH_LOAD;
}
