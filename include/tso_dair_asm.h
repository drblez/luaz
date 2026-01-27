/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * DAIR ASM wrapper interfaces for TSO dynamic allocation.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | tsodalc_call | function | Allocate a private DD and redirect SYSTSPRT |
 * | tsodfre_call | function | Free SYSTSPRT and the private DD allocation |
 * | tsodalo_call | function | Allocate a private DD without SYSTSPRT changes |
 * | tsodflo_call | function | Free a private DD allocation without SYSTSPRT |
 *
 * User Actions:
 * - Ensure DAIR is available under TMP (IKJEFT01) before invoking.
 * - Link TSODALC/TSODFRE into an APF-authorized library if required by site policy.
 * - Provide a 31-bit work buffer of at least TSODAIR_WORKSIZE bytes.
 *
 * Platform Requirements:
 * - LE: required (OS linkage).
 * - AMODE: 31-bit.
 * - EBCDIC: DDNAME/DSNAME strings.
 * - DDNAME I/O: SYSTSPRT redirection.
 */
#ifndef TSO_DAIR_ASM_H
#define TSO_DAIR_ASM_H

#ifdef __cplusplus
extern "C" {
#endif

/* Keep in sync with the largest WORKSIZE in DAIR ASM wrappers. */
#define TSODAIR_WORKSIZE 300

#pragma linkage(tsodalc_call, OS)
#pragma linkage(tsodfre_call, OS)
#pragma linkage(tsodalo_call, OS)
#pragma linkage(tsodflo_call, OS)
#pragma map(tsodalc_call, "TSODALC")
#pragma map(tsodfre_call, "TSODFRE")
#pragma map(tsodalo_call, "TSODALO")
#pragma map(tsodflo_call, "TSODFLO")
/**
 * @brief Allocate a private DD and redirect SYSTSPRT using DAIR.
 *
 * @param cppl CPPL pointer for TSO/E services.
 * @param ddname NUL-terminated DDNAME to allocate (EBCDIC, 8 chars).
 * @param dair_rc Optional pointer to receive DAIR return code.
 * @param cat_rc Optional pointer to receive catalog return code.
 * @param dair_flg Optional pointer to receive DAIR flag byte.
 * @param work 31-bit work area of at least TSODAIR_WORKSIZE bytes.
 * @return 0 on success, or nonzero on failure.
 */
int tsodalc_call(void *cppl, const char *ddname, int *dair_rc, int *cat_rc,
                 void *work);
/**
 * @brief Free the private DD allocation and restore SYSTSPRT via DAIR.
 *
 * @param cppl CPPL pointer for TSO/E services.
 * @param ddname NUL-terminated DDNAME to free (EBCDIC, 8 chars).
 * @param dair_rc Optional pointer to receive DAIR return code.
 * @param cat_rc Optional pointer to receive catalog return code.
 * @param work 31-bit work area of at least TSODAIR_WORKSIZE bytes.
 * @return 0 on success, or nonzero on failure.
 */
int tsodfre_call(void *cppl, const char *ddname, int *dair_rc, int *cat_rc,
                 void *work);
/**
 * @brief Allocate a private DD via DAIR without SYSTSPRT redirection.
 *
 * @param cppl CPPL pointer for TSO/E services.
 * @param ddname NUL-terminated DDNAME to allocate (EBCDIC, 8 chars).
 * @param work 31-bit work area of at least TSODAIR_WORKSIZE bytes.
 * @return 0 on success, or nonzero on failure.
 */
int tsodalo_call(void *cppl, const char *ddname, void *work);
/**
 * @brief Free a private DD allocation via DAIR without SYSTSPRT changes.
 *
 * @param cppl CPPL pointer for TSO/E services.
 * @param ddname NUL-terminated DDNAME to free (EBCDIC, 8 chars).
 * @param dair_rc Optional pointer to receive DAIR return code.
 * @param cat_rc Optional pointer to receive catalog return code.
 * @param work 31-bit work area of at least TSODAIR_WORKSIZE bytes.
 * @return 0 on success, or nonzero on failure.
 */
int tsodflo_call(void *cppl, const char *ddname, int *dair_rc, int *cat_rc,
                 void *work);

#ifdef __cplusplus
}
#endif

#endif /* TSO_DAIR_ASM_H */
