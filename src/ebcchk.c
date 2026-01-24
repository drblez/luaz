/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * EBCCHK - verify ASCII to EBCDIC conversion for FTP-transferred sources.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | lua_tso_ebcchk_dump_codes | function | Print byte codes for "ABC" literal |
 * | main | function | Program entry for byte-code validation |
 *
 * Platform Requirements:
 * - LE: required (C runtime).
 * - AMODE: 31-bit.
 * - EBCDIC: string literal bytes expected in EBCDIC.
 * - DDNAME I/O: stdout (SYSOUT/SYSTSPRT).
 */
#include <stdio.h>
#include <string.h>

#define EBCCHK_EXPECT_A 0xC1
#define EBCCHK_EXPECT_B 0xC2
#define EBCCHK_EXPECT_C 0xC3

/**
 * @brief Print byte codes for a string literal and validate EBCDIC bytes.
 *
 * @param label Output label for diagnostics.
 * @param text Pointer to the literal bytes.
 * @param len Length of the literal in bytes.
 * @return 0 when bytes match EBCDIC C1/C2/C3, or 8 on mismatch.
 */
static int lua_tso_ebcchk_dump_codes(const char *label,
                                     const unsigned char *text, size_t len)
{
  unsigned int b0 = 0;
  unsigned int b1 = 0;
  unsigned int b2 = 0;

  if (text == NULL || len < 3) {
    printf("LUZ40082 %s invalid length=%lu\n",
           label ? label : "EBCCHK", (unsigned long)len);
    return 8;
  }

  b0 = text[0];
  b1 = text[1];
  b2 = text[2];
  printf("LUZ40080 %s bytes: %02X %02X %02X\n", label, b0, b1, b2);

  if (b0 != EBCCHK_EXPECT_A || b1 != EBCCHK_EXPECT_B ||
      b2 != EBCCHK_EXPECT_C) {
    printf("LUZ40082 %s mismatch expected=C1 C2 C3 got=%02X %02X %02X\n",
           label, b0, b1, b2);
    return 8;
  }

  return 0;
}

/**
 * @brief Program entry point for ASCII/EBCDIC conversion verification.
 *
 * @param argc Argument count (unused).
 * @param argv Argument vector (unused).
 * @return 0 on success, or 8 if the literal does not match EBCDIC bytes.
 */
int main(int argc, char **argv)
{
  static const unsigned char text[] = "ABC";
  (void)argc;
  (void)argv;

  return lua_tso_ebcchk_dump_codes("EBCCHK C", text, sizeof(text) - 1);
}
