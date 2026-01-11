/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO DDNAME I/O helpers for LUAPATH.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | luaz_io_dd_register | function | Register DDNAME-based LUAPATH hooks |
 */
#ifndef LUAZ_IO_DD_H
#define LUAZ_IO_DD_H

#ifdef __cplusplus
extern "C" {
#endif

int luaz_io_dd_register(void);

#ifdef __cplusplus
}
#endif

#endif /* LUAZ_IO_DD_H */
