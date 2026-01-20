/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Native TSO backend interface (no REXX).
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | tso_native_env_init | function | Validate TSO environment for native services |
 * | tso_native_cmd | function | Execute a TSO command via native services |
 * | tso_native_alloc | function | Dynamic allocation via DAIR |
 * | tso_native_free | function | Dynamic deallocation via DAIR |
 * | tso_native_msg | function | Emit a TSO message |
 *
 * User Actions:
 * - Ensure job runs under a TSO-capable environment (TMP).
 * - Allocate required DDs (SYSTSPRT/SYSOUT) if output is expected.
 */
#ifndef TSO_NATIVE_H
#define TSO_NATIVE_H

#ifdef __cplusplus
extern "C" {
#endif

int tso_native_env_init(void);
int tso_native_cmd(const char *cmd, const char *outdd);
int tso_native_alloc(const char *spec);
int tso_native_free(const char *spec);
int tso_native_msg(const char *text, int level);

#ifdef __cplusplus
}
#endif

#endif /* TSO_NATIVE_H */
