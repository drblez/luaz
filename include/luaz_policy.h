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
#ifndef LUAZ_POLICY_H
#define LUAZ_POLICY_H

#ifdef __cplusplus
extern "C" {
#endif

int luaz_policy_get(const char *key, char *out, unsigned long *len);

#ifdef __cplusplus
}
#endif

#endif /* LUAZ_POLICY_H */
