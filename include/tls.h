/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO TLS API stubs.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | lua_tls_connect | function | Open TLS connection |
 * | lua_tls_listen | function | Optional TLS server |
 */
#ifndef TLS_H
#define TLS_H

#ifdef __cplusplus
extern "C" {
#endif

int lua_tls_connect(const char *params);
int lua_tls_listen(const char *params);

#ifdef __cplusplus
}
#endif

#endif /* TLS_H */
