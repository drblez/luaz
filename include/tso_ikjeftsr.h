/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * IKJEFTSR (TSO/E Service Facility) parameter list helpers.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | tso_eftsr_flags | struct | Flag bytes for IKJEFTSR parameter 1 |
 * | TSO_EFTSR_* | macro | Flag byte values (IBM-defined) |
 * | tso_eftsr_last | macro | Mark last parm address (high-order bit) |
 *
 * User Actions:
 * - Confirm flag byte semantics against IBM docs before production use.
 */
#ifndef TSO_IKJEFTSR_H
#define TSO_IKJEFTSR_H

#include <stdint.h>

typedef struct tso_eftsr_flags {
  unsigned char b1;
  unsigned char b2;
  unsigned char b3;
  unsigned char b4;
} tso_eftsr_flags;

/* Byte 2: authorized vs unauthorized environment */
#define TSO_EFTSR_AUTH   0x00
#define TSO_EFTSR_UNAUTH 0x01

/* Byte 3: abend processing */
#define TSO_EFTSR_NODUMP 0x00
#define TSO_EFTSR_DUMP   0x01

/* Byte 4: function selector */
#define TSO_EFTSR_CMD    0x01
#define TSO_EFTSR_PROG   0x02
#define TSO_EFTSR_EITHER 0x05

#define TSO_EFTSR_LAST_PTR(p) ((void *)((uintptr_t)(p) | (uintptr_t)0x80000000u))

#endif /* TSO_IKJEFTSR_H */
