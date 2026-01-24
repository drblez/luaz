/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * A2CCALL - C entrypoints for ASM->C OS-linkage validation.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | a2c_scale | function | Multiply two integers into out-parameter |
 * | a2c_strlen | function | Return string length for ASM caller |
 * | a2c_add64 | function | Add two 64-bit values into out-parameter |
 *
 * Platform Requirements:
 * - LE: required (C runtime).
 * - AMODE: 31-bit.
 * - EBCDIC: inputs/outputs are EBCDIC in batch.
 * - DDNAME I/O: no direct I/O; ASM caller handles output.
 */
#include <stdio.h>
#include <string.h>

/**
 * @brief Multiply two integers and store the result via out-parameter.
 *
 * @param a First operand.
 * @param b Second operand.
 * @param out Pointer to output integer.
 * @return 0 on success, or 8 when out is NULL.
 */
#pragma map(a2c_scale, "A2CSCAL")
#pragma linkage(a2c_scale, OS)
int a2c_scale(int a, int b, int *out)
{
  if (out == NULL)
    return 8;
  /* Change: log cscale inputs and output for batch diagnostics. */
  /* Problem: UTA2C cscale value mismatch hides actual args/out. */
  /* Expected effect: reveal actual values seen by C and written result. */
  fprintf(stderr, "LUZ40164 UTA2C cscale args a=%d b=%d out=%p\n",
          a, b, (void *)out);
  *out = a * b;
  fprintf(stderr, "LUZ40165 UTA2C cscale wrote=%d\n", *out);
  return 0;
}

/**
 * @brief Compute string length for ASM caller.
 *
 * @param s Pointer to NUL-terminated string.
 * @return String length, or 8 when s is NULL.
 */
#pragma map(a2c_strlen, "A2CSTRL")
#pragma linkage(a2c_strlen, OS)
int a2c_strlen(const char *s)
{
  if (s == NULL)
    return 8;
  return (int)strlen(s);
}

/**
 * @brief Add two 64-bit values and store the result via out-parameter.
 *
 * @param a First 64-bit operand.
 * @param b Second 64-bit operand.
 * @param out Pointer to output 64-bit value.
 * @return 0 on success, or 8 when out is NULL.
 */
#pragma map(a2c_add64, "A2CADD64")
#pragma linkage(a2c_add64, OS)
int a2c_add64(long long a, long long b, long long *out)
{
  if (out == NULL)
    return 8;
  *out = a + b;
  return 0;
}
