/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO TSO host API stubs.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | lua_tso_cmd | function | Execute a TSO command |
 * | lua_tso_alloc | function | Allocate a dataset |
 * | lua_tso_free | function | Free a dataset allocation |
 * | lua_tso_msg | function | Emit a TSO message |
 * | lua_tso_exit | function | Exit with RC |
 * | lua_tso_set_cppl_cmd | function | Cache CPPL for IKJEFTSR command calls |
 *
 * Note: REXX-based execution is legacy/compatibility only. Do not
 * modify or extend REXX paths unless explicitly requested; direct
 * TSO is the active development path.
 *
 * Change note: record REXX restriction in TSO public header.
 * Problem: REXX path must not be extended without approval.
 * Expected effect: contributors avoid REXX changes by default.
 * Impact: documents policy; runtime behavior unchanged.
 */
#ifndef TSO_H
#define TSO_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Execute a TSO command and return a status code.
 *
 * @param cmd NUL-terminated TSO command string (EBCDIC).
 * @return 0 on success, or LUZ_E_TSO_CMD on failure.
 */
int lua_tso_cmd(const char *cmd);
/**
 * @brief Allocate a dataset or DD using native TSO services.
 *
 * @param spec Allocation specification string.
 * @return 0 on success, or LUZ_E_TSO_ALLOC on failure.
 */
int lua_tso_alloc(const char *spec);
/**
 * @brief Free a dataset or DD allocation using native TSO services.
 *
 * @param spec Deallocation specification string.
 * @return 0 on success, or LUZ_E_TSO_FREE on failure.
 */
int lua_tso_free(const char *spec);
/**
 * @brief Emit a TSO message through the native backend.
 *
 * @param text Message text.
 * @param level Message severity/level.
 * @return 0 on success, or LUZ_E_TSO_MSG on failure.
 */
int lua_tso_msg(const char *text, int level);
/**
 * @brief Exit the caller with a specified return code.
 *
 * @param rc Return code to propagate.
 * @return rc unchanged.
 */
int lua_tso_exit(int rc);
/**
 * @brief Cache a CPPL pointer value for IKJEFTSR command execution.
 *
 * Change note: publish a CPPL setter for command execution.
 * Problem: LUACMD CPPL could not be forwarded through C APIs.
 * Expected effect: callers can cache CPPL for IKJEFTSR optional params.
 * Impact: enables CPPL-aware tso.cmd execution paths.
 * Ref: include/tso.h.md#cppl-setter
 *
 * @param cppl CPPL pointer supplied by LUACMD (address parameter).
 * @return None.
 */
void lua_tso_set_cppl_cmd(void *cppl);

#ifdef __cplusplus
}
#endif

#endif /* TSO_H */
