/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO z/OS time backend hooks for lua-vm.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | luaz_time_now | function | Get current epoch seconds |
 * | luaz_time_local | function | Convert epoch to local time |
 * | luaz_time_gmt | function | Convert epoch to GMT |
 */
#ifndef LUAZ_TIME_STUB_H
#define LUAZ_TIME_STUB_H

#include <time.h>

int luaz_time_now(time_t *out);
int luaz_time_local(const time_t *t, struct tm *out);
int luaz_time_gmt(const time_t *t, struct tm *out);

#endif /* LUAZ_TIME_STUB_H */
