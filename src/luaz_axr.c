/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO AXR API stubs.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | lua_axr_request | function | Execute AXR request (optional) |
 */
#include "luaz_axr.h"

int lua_axr_request(const char *request)
{
  (void)request;
  return -1; /* LUZ-30012 axr.request not implemented */
}
