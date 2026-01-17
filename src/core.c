/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO core runtime stubs.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | luaz_core_init | function | Initialize core runtime |
 * | luaz_core_shutdown | function | Shutdown core runtime |
 */
#include "core.h"
#include "errors.h"

int luaz_core_init(void)
{
  return LUZ_E_CORE_INIT;
}

int luaz_core_shutdown(void)
{
  return LUZ_E_CORE_SHUTDOWN;
}
