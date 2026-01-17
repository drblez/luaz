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
#ifndef POLICY_H
#define POLICY_H

#ifdef __cplusplus
extern "C" {
#endif

int luaz_policy_get(const char *key, char *out, unsigned long *len);

#ifdef __cplusplus
}
#endif

#endif /* POLICY_H */
