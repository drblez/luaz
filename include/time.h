/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * z/OS time backend hooks for Lua/TSO.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | luaz_time_now | function | Get current epoch seconds |
 * | luaz_time_local | function | Convert epoch to local time |
 * | luaz_time_gmt | function | Convert epoch to GMT |
 * | luaz_time_clock | function | Get process CPU time in seconds |
 * | luaz_time_date | function | Format date/time for Lua |
 * | luaz_time_time | function | Compute time for Lua |
 */
#ifndef TIME_H
#define TIME_H

#include <time.h>
#include "LUA"

#ifdef __cplusplus
extern "C" {
#endif

int luaz_time_now(time_t *out);
int luaz_time_local(const time_t *t, struct tm *out);
int luaz_time_gmt(const time_t *t, struct tm *out);
int luaz_time_clock(double *out_seconds);
int luaz_time_date(lua_State *L, const char *fmt, size_t fmtlen);
int luaz_time_time(lua_State *L);

#ifdef __cplusplus
}
#endif

#endif /* TIME_H */
