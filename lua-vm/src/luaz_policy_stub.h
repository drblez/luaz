/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO policy/config hooks for lua-vm.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | luaz_policy_get | function | Read key from policy dataset |
 */
#ifndef LUAZ_POLICY_STUB_H
#define LUAZ_POLICY_STUB_H

int luaz_policy_get(const char *key, char *out, unsigned long *len);

#endif /* LUAZ_POLICY_STUB_H */
