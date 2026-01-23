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
 * | tso_native_cmd_cp | function | Execute a TSO command via TSOAUTH command processor |
 * | tso_native_cmd_cleanup | function | Release internal DD allocations after command |
 * | tso_native_set_cppl | function | Set CPPL pointer from TSO command processor |
 * | tso_native_alloc | function | Dynamic allocation via DAIR |
 * | tso_native_free | function | Dynamic deallocation via DAIR |
 * | tso_native_msg | function | Emit a TSO message |
 *
 * User Actions:
 * - Ensure job runs under a TSO-capable environment (TMP).
 * - Output capture uses an internal DD; no user-supplied DDNAME is required.
 * - Run cleanup after reading the DD to restore SYSTSPRT.
 */
#ifndef TSO_NATIVE_H
#define TSO_NATIVE_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Validate or discover the LE/TSO environment for native services.
 *
 * @return 0 on success, LUZ_E_TSO_CMD on failure.
 */
int tso_native_env_init(void);

/**
 * @brief Execute a TSO command via IKJEFTSR using the ASM TSOCMD path.
 *
 * @param cmd NUL-terminated command string (EBCDIC).
 * @param outdd Output buffer for the generated DDNAME (8 chars + NUL).
 * @param outdd_len Size of outdd in bytes.
 * @param reason Optional pointer to receive IKJEFTSR reason code.
 * @param abend Optional pointer to receive IKJEFTSR abend code.
 * @param dair_rc Optional pointer to receive DAIR return code.
 * @param cat_rc Optional pointer to receive catalog return code.
 * @return 0 on success, or LUZ_E_TSO_CMD on failure.
 */
int tso_native_cmd(const char *cmd, char *outdd, size_t outdd_len,
                   int *reason, int *abend, int *dair_rc, int *cat_rc);

/**
 * @brief Execute a TSO command through the TSOAUTH command processor.
 *
 * @param cmd NUL-terminated command string (EBCDIC).
 * @param outdd Output buffer for the generated DDNAME (8 chars + NUL).
 * @param outdd_len Size of outdd in bytes.
 * @param reason Optional pointer to receive IKJEFTSR reason code.
 * @param abend Optional pointer to receive IKJEFTSR abend code.
 * @param dair_rc Optional pointer to receive DAIR return code.
 * @param cat_rc Optional pointer to receive catalog return code.
 * @return 0 on success, or LUZ_E_TSO_CMD on failure.
 */
int tso_native_cmd_cp(const char *cmd, char *outdd, size_t outdd_len,
                      int *reason, int *abend, int *dair_rc, int *cat_rc);

/**
 * @brief Free the internal DDNAME allocation after reading command output.
 *
 * @param outdd NUL-terminated DDNAME used for output capture.
 * @return 0 on success, or LUZ_E_TSO_CMD on failure.
 */
int tso_native_cmd_cleanup(const char *outdd);

/**
 * @brief Cache the CPPL pointer provided by a TSO command processor.
 *
 * @param cppl CPPL pointer supplied by the command processor entry.
 */
void tso_native_set_cppl(void *cppl);

/**
 * @brief Placeholder for DAIR allocation wrapper (not implemented).
 *
 * @param spec Allocation specification string.
 * @return LUZ_E_TSO_ALLOC to indicate unimplemented function.
 */
int tso_native_alloc(const char *spec);

/**
 * @brief Placeholder for DAIR deallocation wrapper (not implemented).
 *
 * @param spec Allocation specification string.
 * @return LUZ_E_TSO_FREE to indicate unimplemented function.
 */
int tso_native_free(const char *spec);

/**
 * @brief Placeholder for native TSO message emission (not implemented).
 *
 * @param text Message text.
 * @param level Message severity/level.
 * @return LUZ_E_TSO_MSG to indicate unimplemented function.
 */
int tso_native_msg(const char *text, int level);

#ifdef __cplusplus
}
#endif

#endif /* TSO_NATIVE_H */
