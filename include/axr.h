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
#ifndef AXR_H
#define AXR_H

#ifdef __cplusplus
extern "C" {
#endif

int lua_axr_request(const char *request);

#ifdef __cplusplus
}
#endif

#endif /* AXR_H */
