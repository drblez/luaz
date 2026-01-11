/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO platform abstraction layer for z/OS C/LE.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | luaz_platform_ops | struct | Host hooks for dataset I/O, logging, and environment |
 * | luaz_platform_set_ops | function | Register platform hooks |
 */
#ifndef LUAZ_PLATFORM_H
#define LUAZ_PLATFORM_H

#ifdef __cplusplus
extern "C" {
#endif

struct luaz_platform_ops {
  int (*log_msg)(const char *code, const char *msg);
  int (*read_dd)(const char *ddname, void *buf, unsigned long *len);
  int (*write_dd)(const char *ddname, const void *buf, unsigned long len);
  int (*get_env)(const char *key, char *out, unsigned long *len);
  int (*luapath_read_luamap)(char *buf, unsigned long *len);
  int (*luapath_read_member)(const char *member, char *buf, unsigned long *len);
};

int luaz_platform_set_ops(const struct luaz_platform_ops *ops);

#ifdef __cplusplus
}
#endif

#endif /* LUAZ_PLATFORM_H */
