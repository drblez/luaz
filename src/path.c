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
#include "ERRORS"
#include "PATH"

#include <ctype.h>
#include <stdlib.h>
#include <string.h>

static struct luaz_path_ops g_ops;

int luaz_path_set_ops(const struct luaz_path_ops *ops)
{
  if (ops == NULL)
    return LUZ_E_PATH_LOOKUP;
  g_ops = *ops;
  return 0;
}

static void trim_spaces(char **start, char **end)
{
  while (*start < *end && isspace((unsigned char)**start))
    (*start)++;
  while (*end > *start && isspace((unsigned char)*((*end) - 1)))
    (*end)--;
}

int luaz_path_lookup(const char *modname, char *member, unsigned long *len)
{
  unsigned long blen = 0;
  char *buf;
  char *p;
  char *line;

  if (modname == NULL || member == NULL || len == NULL)
    return LUZ_E_PATH_LOOKUP;
  if (g_ops.luamap_read == NULL)
    return LUZ_E_PATH_LOOKUP;

  if (g_ops.luamap_read(NULL, &blen) != 0 || blen == 0)
    return LUZ_E_PATH_LOOKUP;

  buf = (char *)malloc(blen + 1);
  if (buf == NULL)
    return LUZ_E_PATH_LOOKUP;

  if (g_ops.luamap_read(buf, &blen) != 0) {
    free(buf);
    return LUZ_E_PATH_LOOKUP;
  }
  buf[blen] = '\0';

  p = buf;
  while ((line = p) != NULL) {
    char *nl = strchr(p, '\n');
    char *start;
    char *end;
    char *eq;
    if (nl) {
      *nl = '\0';
      p = nl + 1;
    }
    else {
      p = NULL;
    }

    start = line;
    end = line + strlen(line);
    trim_spaces(&start, &end);
    if (start == end)
      continue;
    if (*start == '#' || *start == ';')
      continue;
    eq = memchr(start, '=', (size_t)(end - start));
    if (!eq)
      continue;
    {
      char *lstart = start;
      char *lend = eq;
      char *rstart = eq + 1;
      char *rend = end;
      trim_spaces(&lstart, &lend);
      trim_spaces(&rstart, &rend);
      if ((size_t)(lend - lstart) == strlen(modname) &&
          memcmp(lstart, modname, (size_t)(lend - lstart)) == 0) {
        unsigned long mlen = (unsigned long)(rend - rstart);
        if (mlen == 0 || mlen > 8) {
          free(buf);
          return LUZ_E_PATH_LOOKUP;
        }
        if (*len <= mlen) {
          free(buf);
          return LUZ_E_PATH_LOOKUP;
        }
        memcpy(member, rstart, mlen);
        member[mlen] = '\0';
        *len = mlen;
        free(buf);
        return 0;
      }
    }
  }

  free(buf);
  return LUZ_E_PATH_LOOKUP;
}

int luaz_path_load(const char *modname, const char *member,
                   char *buf, unsigned long *len)
{
  (void)modname;
  if (member == NULL || len == NULL)
    return LUZ_E_PATH_LOAD;
  if (g_ops.member_read == NULL)
    return LUZ_E_PATH_LOAD;
  return g_ops.member_read(member, buf, len);
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
