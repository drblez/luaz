/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO LUAPATH lookup and load hooks for lua-vm.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | luaz_path_lookup | function | Map long module name to member via LUAMAP |
 * | luaz_path_load | function | Load module source from LUAPATH |
 */
#ifndef PTHSTB_H
#define PTHSTB_H

int luaz_path_lookup(const char *modname, char *member, unsigned long *len);
int luaz_path_load(const char *modname, const char *member,
                   char *buf, unsigned long *len);
int luaz_path_resolve(const char *modname, char *member, unsigned long *len);

#endif /* PTHSTB_H */
