/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * C2ATEST - C->ASM OS-linkage validation for non-XPLINK.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | c2a_pair | type | Pair of integers with sum output field |
 * | c2a_add2 | extern function | Add two integers in ASM |
 * | c2a_strlen | extern function | Compute string length in ASM |
 * | c2a_sum_pair | extern function | Sum struct fields in ASM |
 * | c2a_add64 | extern function | Add two 64-bit values in ASM |
 * | main | function | Validate C->ASM parameter passing and return codes |
 *
 * Platform Requirements:
 * - LE: required (C runtime).
 * - AMODE: 31-bit.
 * - EBCDIC: literals and output are EBCDIC in batch.
 * - DDNAME I/O: stdout via SYSOUT/SYSTSPRT.
 */
#include <stdio.h>
#include <string.h>

/* Pair of integers with sum output field for ASM validation. */
typedef struct c2a_pair {
  int a;
  int b;
  int sum;
} c2a_pair;

/**
 * @brief Add two integers in ASM and return the sum.
 *
 * @param a First integer operand.
 * @param b Second integer operand.
 * @return Sum of a and b.
 */
#pragma map(c2a_add2, "C2AADD2")
#pragma linkage(c2a_add2, OS)
int c2a_add2(int a, int b);

/**
 * @brief Compute string length in ASM.
 *
 * @param s NUL-terminated string pointer.
 * @return Length in bytes, or nonzero RC on failure.
 */
#pragma map(c2a_strlen, "C2ASTRL")
#pragma linkage(c2a_strlen, OS)
int c2a_strlen(const char *s);

/**
 * @brief Sum two integer fields into the output field in ASM.
 *
 * @param p Pointer to a c2a_pair with fields a/b and sum output.
 */
#pragma map(c2a_sum_pair, "C2ASUM")
#pragma linkage(c2a_sum_pair, OS)
void c2a_sum_pair(c2a_pair *p);

/**
 * @brief Add two 64-bit integers in ASM using an out-parameter.
 *
 * @param a First 64-bit operand.
 * @param b Second 64-bit operand.
 * @param out Pointer to a 64-bit result buffer.
 * @return 0 on success, or 8 on failure (invalid pointer).
 */
#pragma map(c2a_add64, "C2AADD64")
#pragma linkage(c2a_add64, OS)
int c2a_add64(long long a, long long b, long long *out);

/**
 * @brief Program entry point for C->ASM OS-linkage validation.
 *
 * @param argc Argument count (unused).
 * @param argv Argument vector (unused).
 * @return 0 on success, or 8 on validation failure.
 */
int main(int argc, char **argv)
{
  int rc = 0;
  int val = 0;
  int len = 0;
  long long out64 = 0;
  const char *text = "HELLO";
  c2a_pair pair = {7, 9, 0};

  (void)argc;
  (void)argv;

  printf("LUZ40100 UTC2A start\n");

  val = c2a_add2(10, 32);
  if (val != 42) {
    printf("LUZ40150 UTC2A add2 failed got=%d\n", val);
    return 8;
  }
  printf("LUZ40101 UTC2A add2 ok\n");

  len = c2a_strlen(text);
  if (len != 5) {
    printf("LUZ40151 UTC2A strlen failed got=%d\n", len);
    return 8;
  }
  printf("LUZ40102 UTC2A strlen ok\n");

  c2a_sum_pair(&pair);
  if (pair.sum != 16) {
    printf("LUZ40152 UTC2A sum failed got=%d\n", pair.sum);
    return 8;
  }
  printf("LUZ40103 UTC2A sum ok\n");

  rc = c2a_add64(0x1122334455667788LL, 0x10LL, &out64);
  if (rc != 0 || out64 != 0x1122334455667798LL) {
    printf("LUZ40153 UTC2A add64 failed rc=%d val=%lld\n", rc, out64);
    return 8;
  }
  printf("LUZ40104 UTC2A add64 ok\n");

  printf("LUZ40109 UTC2A success\n");
  return 0;
}
