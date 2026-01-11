/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO TSO host API stubs.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | lua_tso_cmd | function | Execute a TSO command |
 * | lua_tso_alloc | function | Allocate a dataset |
 * | lua_tso_free | function | Free a dataset allocation |
 */
#ifndef LUAZ_TSO_H
#define LUAZ_TSO_H

#ifdef __cplusplus
extern "C" {
#endif

int lua_tso_cmd(const char *cmd);
int lua_tso_alloc(const char *spec);
int lua_tso_free(const char *spec);

#ifdef __cplusplus
}
#endif

#endif /* LUAZ_TSO_H */
