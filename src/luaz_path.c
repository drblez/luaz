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

#include <ctype.h>
#include <string.h>

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

int luaz_path_resolve(const char *modname, char *member, unsigned long *len)
{
  size_t nlen;
  unsigned long cap;
  size_t i;

  if (modname == NULL || member == NULL || len == NULL)
    return LUZ_E_PATH_LOOKUP;

  nlen = strlen(modname);
  cap = *len;
  if (cap == 0)
    return LUZ_E_PATH_LOOKUP;

  if (nlen <= 8) {
    if (cap <= nlen)
      return LUZ_E_PATH_LOOKUP;
    for (i = 0; i < nlen; i++) {
      unsigned char c = (unsigned char)modname[i];
      if (c == '.')
        c = '$';
      c = (unsigned char)toupper(c);
      if (!(c == '$' || c == '#' || c == '@' || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9')))
        c = '#';
      member[i] = (char)c;
    }
    member[nlen] = '\0';
    *len = (unsigned long)nlen;
    return 0;
  }

  if (luaz_path_lookup(modname, member, len) != 0)
    return LUZ_E_PATH_LOOKUP;
  if (*len == 0 || *len > 8)
    return LUZ_E_PATH_LOOKUP;
  member[*len] = '\0';
  return 0;
}
