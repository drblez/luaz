/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * DS open_dd unit test helper for z/OS batch.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | main | function | Validate ds.open_dd read/write via DDNAME |
 */
#include "DS"

#include <errno.h>
#include <stdio.h>
#include <string.h>

static int read_check(const char *ddname, const char *expect)
{
  struct lua_ds_handle *h = NULL;
  char buf[128];
  unsigned long len = sizeof(buf) - 1;
  if (lua_ds_open_dd(ddname, "r", &h) != 0)
    return 1;
  if (lua_ds_read(h, buf, &len) != 0) {
    lua_ds_close(h);
    return 2;
  }
  buf[len] = '\0';
  lua_ds_close(h);
  if (len == 0)
    return 3;
  return (strncmp(buf, expect, strlen(expect)) == 0) ? 0 : 4;
}

static int write_text(const char *ddname, const char *text)
{
  struct lua_ds_handle *h = NULL;
  if (lua_ds_open_dd(ddname, "w", &h) != 0)
    return 0;
  if (lua_ds_write(h, text, (unsigned long)strlen(text)) != 0) {
    lua_ds_close(h);
    return 0;
  }
  lua_ds_close(h);
  return 1;
}

int main(int argc, char **argv)
{
  if (argc > 1 && strcmp(argv[1], "VERIFY") == 0) {
    int rc = read_check("DDCHECK", "WORLD");
    if (rc != 0) {
      if (rc == 1) {
        printf("LUZ00006 DS UT verify open failed errno=%d errno2=%d\n",
               errno, __errno2());
      }
      else if (rc == 2) puts("LUZ00007 DS UT verify read failed");
      else if (rc == 3) puts("LUZ00008 DS UT verify empty");
      else puts("LUZ00005 DS UT verify failed");
      return 8;
    }
    puts("LUZ00004 DS UT OK");
    return 0;
  }

  {
    int rc = read_check("DSIN", "HELLO");
    if (rc != 0) {
      if (rc == 1) {
        printf("LUZ00006 DS UT read open failed errno=%d errno2=%d\n",
               errno, __errno2());
      }
      else if (rc == 2) puts("LUZ00007 DS UT read failed");
      else if (rc == 3) puts("LUZ00008 DS UT read empty");
      else puts("LUZ00005 DS UT read mismatch");
      return 8;
    }
  }

  if (!write_text("DSOUT", "WORLD\n")) {
    puts("LUZ00005 DS UT write failed");
    return 8;
  }

  puts("LUZ00004 DS UT OK");
  return 0;
}
