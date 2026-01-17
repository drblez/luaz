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
#include "DS"
#include "ERRORS"

struct lua_ds_handle {
  int reserved;
};

int lua_ds_open_dd(const char *ddname, struct lua_ds_handle **out)
{
  (void)ddname;
  if (out) {
    *out = 0;
  }
  return LUZ_E_DS_OPEN;
}

int lua_ds_read(struct lua_ds_handle *h, void *buf, unsigned long *len)
{
  (void)h;
  (void)buf;
  if (len) {
    *len = 0;
  }
  return LUZ_E_DS_READ;
}

int lua_ds_write(struct lua_ds_handle *h, const void *buf, unsigned long len)
{
  (void)h;
  (void)buf;
  (void)len;
  return LUZ_E_DS_WRITE;
}

int lua_ds_close(struct lua_ds_handle *h)
{
  (void)h;
  return LUZ_E_DS_CLOSE;
}
