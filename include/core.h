/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO core initialization and shutdown.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | luaz_core_init | function | Initialize core runtime |
 * | luaz_core_shutdown | function | Shutdown core runtime |
 */
#ifndef CORE_H
#define CORE_H

#ifdef __cplusplus
extern "C" {
#endif

int luaz_core_init(void);
int luaz_core_shutdown(void);

#ifdef __cplusplus
}
#endif

#endif /* CORE_H */
