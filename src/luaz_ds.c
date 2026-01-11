/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO dataset API stubs.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | lua_ds_open_dd | function | Open DDNAME stream |
 * | lua_ds_read | function | Read from DDNAME stream |
 * | lua_ds_write | function | Write to DDNAME stream |
 * | lua_ds_close | function | Close DDNAME stream |
 */
#include "luaz_ds.h"

struct lua_ds_handle {
  int reserved;
};

int lua_ds_open_dd(const char *ddname, struct lua_ds_handle **out)
{
  (void)ddname;
  if (out) {
    *out = 0;
  }
  return -1; /* LUZ-30006 ds.open_dd not implemented */
}

int lua_ds_read(struct lua_ds_handle *h, void *buf, unsigned long *len)
{
  (void)h;
  (void)buf;
  if (len) {
    *len = 0;
  }
  return -1; /* LUZ-30007 ds.read not implemented */
}

int lua_ds_write(struct lua_ds_handle *h, const void *buf, unsigned long len)
{
  (void)h;
  (void)buf;
  (void)len;
  return -1; /* LUZ-30008 ds.write not implemented */
}

int lua_ds_close(struct lua_ds_handle *h)
{
  (void)h;
  return -1; /* LUZ-30009 ds.close not implemented */
}
