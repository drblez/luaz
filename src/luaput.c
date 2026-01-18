/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * LUAPATH unit test helper for z/OS batch.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | main | function | Validate LUAMAP lookup and LUAPATH member reads |
 */
#include "iodd.h"
#include "path.h"

#include <stdio.h>
#include <string.h>

static int expect_resolve(const char *name, const char *expect)
{
  char member[9];
  unsigned long mlen = sizeof(member) - 1;
  if (luaz_path_resolve(name, member, &mlen) != 0)
    return 0;
  if (strcmp(member, expect) != 0)
    return 0;
  return 1;
}

static int expect_load(const char *name, const char *member)
{
  unsigned long len = 0;
  char buf[128];
  if (luaz_path_load(name, member, NULL, &len) != 0 || len == 0)
    return 0;
  if (len >= sizeof(buf))
    return 0;
  if (luaz_path_load(name, member, buf, &len) != 0)
    return 0;
  buf[len] = '\0';
  if (strstr(buf, "return") == NULL)
    return 0;
  return 1;
}

int main(void)
{
  if (luaz_io_dd_register() != 0) {
    puts("LUZ00003 LUAPATH UT register failed");
    return 8;
  }

  if (!expect_resolve("short", "SHORT") ||
      !expect_load("short", "SHORT")) {
    puts("LUZ00003 LUAPATH UT short name failed");
    return 8;
  }

  if (!expect_resolve("very.long.name", "VLONG01") ||
      !expect_load("very.long.name", "VLONG01")) {
    puts("LUZ00003 LUAPATH UT long name failed");
    return 8;
  }

  puts("LUZ00002 LUAPATH UT OK");
  return 0;
}
