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
#include "tls.h"
#include "errors.h"

int lua_tls_connect(const char *params)
{
  (void)params;
  return LUZ_E_TLS_CONNECT;
}

int lua_tls_listen(const char *params)
{
  (void)params;
  return LUZ_E_TLS_LISTEN;
}
