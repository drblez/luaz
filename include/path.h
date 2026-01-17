/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO LUAPATH lookup and load hooks.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | luaz_path_lookup | function | Map long module name to member via LUAMAP |
 * | luaz_path_load | function | Load module source from LUAPATH |
 */
#ifndef PATH_H
#define PATH_H

#ifdef __cplusplus
extern "C" {
#endif

struct luaz_path_ops {
  int (*luamap_read)(char *buf, unsigned long *len);
  int (*member_read)(const char *member, char *buf, unsigned long *len);
};

int luaz_path_lookup(const char *modname, char *member, unsigned long *len);
int luaz_path_load(const char *modname, const char *member,
                   char *buf, unsigned long *len);
int luaz_path_resolve(const char *modname, char *member, unsigned long *len);
int luaz_path_set_ops(const struct luaz_path_ops *ops);

#ifdef __cplusplus
}
#endif

#endif /* PATH_H */
