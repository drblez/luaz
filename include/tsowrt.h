/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Minimal write test for ASM storage access.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | tsowrt_call | function | Write a test byte into a caller buffer |
 *
 * User Actions:
 * - Ensure module is linked with AC=1 and stored in an APF-authorized library.
 */
#ifndef TSOWRT_H
#define TSOWRT_H

#ifdef __cplusplus
extern "C" {
#endif

#pragma linkage(tsowrt_call, OS)
#pragma map(tsowrt_call, "TSOWRT")
void tsowrt_call(void *buf, int *len, int *rc);

#ifdef __cplusplus
}
#endif

#endif /* TSOWRT_H */
