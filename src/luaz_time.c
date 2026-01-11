/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * z/OS time backend stubs for Lua/TSO.
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
#include "luaz_errors.h"
#include "luaz_time.h"

int luaz_time_now(time_t *out)
{
  (void)out;
  return LUZ_E_TIME_NOW;
}

int luaz_time_local(const time_t *t, struct tm *out)
{
  (void)t;
  (void)out;
  return LUZ_E_TIME_LOCAL;
}

int luaz_time_gmt(const time_t *t, struct tm *out)
{
  (void)t;
  (void)out;
  return LUZ_E_TIME_GMT;
}

int luaz_time_clock(double *out_seconds)
{
  (void)out_seconds;
  return LUZ_E_TIME_CLOCK;
}

int luaz_time_date(lua_State *L, const char *fmt, size_t fmtlen)
{
  (void)L;
  (void)fmt;
  (void)fmtlen;
  return LUZ_E_TIME_DATE;
}

int luaz_time_time(lua_State *L)
{
  (void)L;
  return LUZ_E_TIME_TIME;
}
