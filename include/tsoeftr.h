/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * IKJEFTSR wrapper interface.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | tsoeftr_call | function | Call IKJEFTSR via authorized wrapper |
 *
 * User Actions:
 * - Link TSOEFTR with AC=1 and keep in APF-authorized library.
 */
#ifndef TSOEFTR_H
#define TSOEFTR_H

#ifdef __cplusplus
extern "C" {
#endif

#define TSOEFTR_WORKSIZE 152

#pragma linkage(tsoeftr_call, OS)
#pragma map(tsoeftr_call, "TSOEFTR")
void tsoeftr_call(const char *cmd, int *cmd_len, int *rc, int *reason, int *abend,
                  void *work);

#ifdef __cplusplus
}
#endif

#endif /* TSOEFTR_H */
