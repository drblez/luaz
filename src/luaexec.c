/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * LUAEXEC entrypoint (stub) for z/OS.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | main | function | Entry point for LUAEXEC |
 */
#include "iodd.h"

int main(void)
{
  (void)luaz_io_dd_register();
  return 0;
}
