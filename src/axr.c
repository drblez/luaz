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
#include "axr.h"
#include "errors.h"

int lua_axr_request(const char *request)
{
  (void)request;
  return LUZ_E_AXR_REQUEST;
}
