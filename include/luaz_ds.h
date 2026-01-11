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
#ifndef LUAZ_DS_H
#define LUAZ_DS_H

#ifdef __cplusplus
extern "C" {
#endif

struct lua_ds_handle;

int lua_ds_open_dd(const char *ddname, struct lua_ds_handle **out);
int lua_ds_read(struct lua_ds_handle *h, void *buf, unsigned long *len);
int lua_ds_write(struct lua_ds_handle *h, const void *buf, unsigned long len);
int lua_ds_close(struct lua_ds_handle *h);

#ifdef __cplusplus
}
#endif

#endif /* LUAZ_DS_H */
