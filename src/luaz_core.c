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
#include "luaz_core.h"

int luaz_core_init(void)
{
  return -1; /* LUZ-30001 core init not implemented */
}

int luaz_core_shutdown(void)
{
  return -1; /* LUZ-30002 core shutdown not implemented */
}
