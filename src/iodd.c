/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO DDNAME I/O helpers for LUAPATH.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | luaz_io_dd_register | function | Register DDNAME-based LUAPATH hooks |
 */
#include "iodd.h"
#include "platform.h"

#include <stdio.h>
#include <string.h>

static int read_stream(FILE *fp, char *buf, unsigned long *len)
{
  unsigned long cap;
  unsigned long total = 0;
  size_t n;

  if (len == NULL)
    return -1;
  cap = *len;

  if (buf == NULL) {
    char tmp[512];
    while ((n = fread(tmp, 1, sizeof(tmp), fp)) > 0)
      total += (unsigned long)n;
    *len = total;
    return 0;
  }

  while (total < cap && (n = fread(buf + total, 1, cap - total, fp)) > 0)
    total += (unsigned long)n;
  if (total == cap) {
    int c = fgetc(fp);
    if (c != EOF) {
      ungetc(c, fp);
      return -1;
    }
  }
  *len = total;
  return 0;
}

static int luaz_dd_open(const char *member, FILE **out)
{
  char path[128];
  int rc;

  if (out == NULL || member == NULL)
    return -1;

  rc = snprintf(path, sizeof(path), "//DD:LUAPATH(%s)", member);
  if (rc <= 0 || (size_t)rc >= sizeof(path))
    return -1;

  *out = fopen(path, "r");
  return (*out == NULL) ? -1 : 0;
}

static int luaz_luamap_read(char *buf, unsigned long *len)
{
  FILE *fp = NULL;
  int rc;

  if (luaz_dd_open("LUAMAP", &fp) != 0)
    return -1;

  rc = read_stream(fp, buf, len);
  fclose(fp);
  return rc;
}

static int luaz_member_read(const char *member, char *buf, unsigned long *len)
{
  FILE *fp = NULL;
  int rc;

  if (member == NULL)
    return -1;
  if (luaz_dd_open(member, &fp) != 0)
    return -1;

  rc = read_stream(fp, buf, len);
  fclose(fp);
  return rc;
}

int luaz_io_dd_register(void)
{
  struct luaz_platform_ops ops;
  memset(&ops, 0, sizeof(ops));
  ops.luapath_read_luamap = luaz_luamap_read;
  ops.luapath_read_member = luaz_member_read;
  return luaz_platform_set_ops(&ops);
}
