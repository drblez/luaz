/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * ASM command wrapper interface for native TSO command execution.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | tso_cmd_parms_t | type | Parameter block for TSOCMD |
 * | tsocmd_call | function | Run TSO command using ASM-only path |
 * | TSOCMD_WORKSIZE | macro | Work area size for TSOCMD |
 *
 * Platform Requirements:
 * - LE: required (OS linkage).
 * - AMODE: 31-bit.
 * - EBCDIC: DDNAME/command buffers.
 */
#ifndef TSO_CMD_ASM_H
#define TSO_CMD_ASM_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define TSOCMD_WORKSIZE 1024

/* TSOCMD parameter block (31-bit pointers, OS linkage). */
typedef struct tso_cmd_parms_t {
  void * __ptr32 cppl;
  char * __ptr32 cmd;
  int32_t cmd_len;
  char * __ptr32 outdd;
  int32_t * __ptr32 reason;
  int32_t * __ptr32 abend;
  int32_t * __ptr32 dair_rc;
  int32_t * __ptr32 cat_rc;
  void * __ptr32 work;
} tso_cmd_parms_t;

#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L && !defined(__cplusplus)
_Static_assert(sizeof(tso_cmd_parms_t) == 36, "tso_cmd_parms_t size mismatch");
_Static_assert(offsetof(tso_cmd_parms_t, dair_rc) == 24,
               "tso_cmd_parms_t layout mismatch");
#endif

#pragma linkage(tsocmd_call, OS)
#pragma map(tsocmd_call, "TSOCMD")
/**
 * @brief Execute a TSO command via the TSOCMD assembler entry point.
 *
 * @param parms Pointer to a 31-bit parameter block describing the command.
 * @return 0 on success, or a negative RC on failure (see TSOCMD contract).
 */
int tsocmd_call(tso_cmd_parms_t *parms);

#ifdef __cplusplus
}
#endif

#endif /* TSO_CMD_ASM_H */
