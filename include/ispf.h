/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO ISPF API stubs.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | lua_ispf_qry | function | Query ISPF environment |
 * | lua_ispf_exec | function | Execute ISPF command |
 */
#ifndef ISPF_H
#define ISPF_H

#ifdef __cplusplus
extern "C" {
#endif

int lua_ispf_qry(void);
int lua_ispf_exec(const char *cmdline);

#ifdef __cplusplus
}
#endif

#endif /* ISPF_H */
