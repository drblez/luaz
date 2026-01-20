/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * DAIR parameter list mappings (IKJDAPL/IKJDAP08/IKJDAP18).
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | tso_dapl | struct | DAIR parameter list (pointer block) |
 * | tso_dapb08 | struct | DAIR allocate request block (IKJDAP08) |
 * | tso_dapb18 | struct | DAIR unallocate request block (IKJDAP18) |
 * | TSO_DA08_* | macro | Allocate request flags and options |
 * | TSO_DA18_* | macro | Unallocate request flags and options |
 *
 * User Actions:
 * - Ensure DAIR entry code values match IBM documentation before use.
 * - Verify struct sizes against `SYS1.MACLIB(IKJDAPL/IKJDAP08/IKJDAP18)`.
 */
#ifndef TSO_DAIR_H
#define TSO_DAIR_H

#include <stdint.h>

/* DAIR parameter list (DAPL) */
typedef struct tso_dapl {
  void *upt;    /* DAPLUPT */
  void *ect;    /* DAPLECT */
  void *ecb;    /* DAPLECB */
  void *pscb;   /* DAPLPSCB */
  void *dapb;   /* DAPLDAPB */
} tso_dapl;

/* DAIR allocate request block (DAPB08) */
typedef struct tso_dapb08 {
  char da08cd[2];
  unsigned char da08flg;
  unsigned char da08pad1;
  uint16_t da08darc;
  uint16_t da08ctrc;
  void *da08pdsn;
  char da08ddn[8];
  char da08unit[8];
  char da08ser[8];
  char da08blk[4];
  char da08pqty[4];
  char da08sqty[4];
  char da08dqty[4];
  char da08mnm[8];
  char da08pswd[8];
  unsigned char da08dps2;
  unsigned char da08dps2a;
  unsigned char da08dps3;
  unsigned char da08ctl;
  char da08rsv1[3];
  char da08dso;
  char da08aln[8];
} tso_dapb08;

/* DAIR unallocate request block (DAPB18) */
typedef struct tso_dapb18 {
  char da18cd[2];
  unsigned char da18flg;
  unsigned char da18pad1;
  uint16_t da18darc;
  uint16_t da18ctrc;
  void *da18pdsn;
  char da18ddn[8];
  char da18mnm[8];
  char da18scls[2];
  unsigned char da18dps2;
  unsigned char da18ctl;
  char da18jbnm[8];
} tso_dapb18;

/* DAIR allocate flags/options (DAPB08) */
#define TSO_DA08_SHR  0x08
#define TSO_DA08_NEW  0x04
#define TSO_DA08_MOD  0x02
#define TSO_DA08_OLD  0x01
#define TSO_DA08_KEEP 0x08
#define TSO_DA08_DEL  0x04
#define TSO_DA08_CAT  0x02
#define TSO_DA08_UCAT 0x01
#define TSO_DA08_KEP  0x08
#define TSO_DA08_DELE 0x04
#define TSO_DA08_CATL 0x02
#define TSO_DA08_UNCT 0x01
#define TSO_DA08_TRKS 0x80
#define TSO_DA08_CYLS 0xC0
#define TSO_DA08_UID  0x20
#define TSO_DA08_RLSE 0x10
#define TSO_DA08_PERM 0x08
#define TSO_DA08_ATRL 0x02

/* DAIR unallocate flags/options (DAPB18) */
#define TSO_DA18_KEEP 0x08
#define TSO_DA18_DEL  0x04
#define TSO_DA18_CAT  0x02
#define TSO_DA18_UCAT 0x01
#define TSO_DA18_UID  0x20
#define TSO_DA18_PERM 0x10

#endif /* TSO_DAIR_H */
