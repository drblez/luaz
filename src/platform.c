/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO platform hooks registration.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | luaz_platform_set_ops | function | Register platform hooks |
 */
#include "platform.h"
#include "path.h"

static struct luaz_platform_ops g_ops;
static struct luaz_path_ops g_path_ops;

static int luaz_luamap_read(char *buf, unsigned long *len)
{
  if (g_ops.luapath_read_luamap == 0)
    return -1;
  return g_ops.luapath_read_luamap(buf, len);
}

static int luaz_member_read(const char *member, char *buf, unsigned long *len)
{
  if (g_ops.luapath_read_member == 0)
    return -1;
  return g_ops.luapath_read_member(member, buf, len);
}

int luaz_platform_set_ops(const struct luaz_platform_ops *ops)
{
  if (ops == 0)
    return -1;
  g_ops = *ops;

  if (g_ops.luapath_read_luamap != 0 && g_ops.luapath_read_member != 0) {
    g_path_ops.luamap_read = luaz_luamap_read;
    g_path_ops.member_read = luaz_member_read;
    (void)luaz_path_set_ops(&g_path_ops);
  }

  return 0;
}
