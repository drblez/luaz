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
#include "luaz_tls.h"

int lua_tls_connect(const char *params)
{
  (void)params;
  return -1; /* LUZ-30013 tls.connect not implemented */
}

int lua_tls_listen(const char *params)
{
  (void)params;
  return -1; /* LUZ-30014 tls.listen not implemented */
}
