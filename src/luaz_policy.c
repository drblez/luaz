/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO policy/config access stubs.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | luaz_policy_get | function | Read key from policy dataset |
 */
#include "luaz_errors.h"
#include "luaz_policy.h"

int luaz_policy_get(const char *key, char *out, unsigned long *len)
{
  (void)key;
  if (out && len) {
    *len = 0;
  }
  return LUZ_E_POLICY_GET;
}
