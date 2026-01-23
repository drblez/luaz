//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Unit test for HASHCMP with FB vs VB source formats.
//* Objects:
//* +---------+----------------------------------------------+
//* | ALLOC   | Allocate temp FB/VB source, hash, and OBJ    |
//* | MKFB    | Create FB source member                      |
//* | MKVB    | Create VB source member                      |
//* | MKOBJ   | Create dummy OBJ member for compare checks   |
//* | UFB     | Update hash for FB (expect RC=0)             |
//* | UVB     | Update hash for VB (expect RC=0)             |
//* | CFB     | Compare FB vs FB hash (expect RC=0)          |
//* | CVB     | Compare VB vs VB hash (expect RC=0)          |
//* | XFB     | Compare FB vs VB hash (expect RC=0)          |
//* | XVB     | Compare VB vs FB hash (expect RC=0)          |
//* +---------+----------------------------------------------+
//UTHSHFMT JOB (ACCT),'UT HASHCMP FMT',CLASS=A,MSGCLASS=H,
//         NOTIFY=&SYSUID
//         SET HLQ=DRBLEZ
//         SET LOADLIB=&HLQ..LUA.LOAD
//*
//ALLOC   EXEC PGM=IEFBR14
//FBSRC   DD  DSN=&&FBSRC,
//             DISP=(NEW,PASS,DELETE),
//             DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=0,
//             SPACE=(TRK,(1,1,1)),UNIT=SYSALLDA
//VBSRC   DD  DSN=&&VBSRC,
//             DISP=(NEW,PASS,DELETE),
//             DSORG=PO,RECFM=VB,LRECL=256,BLKSIZE=0,
//             SPACE=(TRK,(1,1,1)),UNIT=SYSALLDA
//FBHASH  DD  DSN=&&FBHASH,
//             DISP=(NEW,PASS,DELETE),
//             DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=0,
//             SPACE=(TRK,(1,1,1)),UNIT=SYSALLDA
//VBHASH  DD  DSN=&&VBHASH,
//             DISP=(NEW,PASS,DELETE),
//             DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=0,
//             SPACE=(TRK,(1,1,1)),UNIT=SYSALLDA
//OBJ     DD  DSN=&&OBJ,
//             DISP=(NEW,PASS,DELETE),
//             DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=0,
//             SPACE=(TRK,(1,1,1)),UNIT=SYSALLDA
//*
//MKFB    EXEC PGM=IEBGENER
//SYSUT1  DD  *
alpha
beta
gamma
//SYSUT2  DD  DSN=&&FBSRC(TEST1),DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSIN   DD  DUMMY
//*
//MKVB    EXEC PGM=IEBGENER
//SYSUT1  DD  *
alpha
beta
gamma
//SYSUT2  DD  DSN=&&VBSRC(TEST1),DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSIN   DD  DUMMY
//* Create dummy OBJ member for compare checks.
//MKOBJ   EXEC PGM=IEBGENER
//SYSUT1  DD  *
OBJ
//SYSUT2  DD  DSN=&&OBJ(TEST1),DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSIN   DD  DUMMY
//*
//UFB     EXEC PGM=HASHCMP,PARM='U TEST1 FBSRC FBHASH'
//STEPLIB  DD  DSN=&LOADLIB,DISP=SHR
//SRCIN    DD  DSN=&&FBSRC(TEST1),DISP=SHR
//HASHOUT  DD  DSN=&&FBHASH(TEST1),DISP=SHR
// IF (UFB.RC NE 0) THEN
//FAIL1   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  SET MAXCC=12
/*
// ENDIF
//UVB     EXEC PGM=HASHCMP,PARM='U TEST1 VBSRC VBHASH'
//STEPLIB  DD  DSN=&LOADLIB,DISP=SHR
//SRCIN    DD  DSN=&&VBSRC(TEST1),DISP=SHR
//HASHOUT  DD  DSN=&&VBHASH(TEST1),DISP=SHR
// IF (UVB.RC NE 0) THEN
//FAIL2   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  SET MAXCC=12
/*
// ENDIF
//CFB     EXEC PGM=HASHCMP,PARM='C TEST1 FBSRC FBHASH'
//STEPLIB  DD  DSN=&LOADLIB,DISP=SHR
//SRCIN    DD  DSN=&&FBSRC(TEST1),DISP=SHR
//OBJIN    DD  DSN=&&OBJ(TEST1),DISP=SHR
//HASHIN   DD  DSN=&&FBHASH(TEST1),DISP=SHR
// IF (CFB.RC NE 0) THEN
//FAIL3   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  SET MAXCC=12
/*
// ENDIF
//CVB     EXEC PGM=HASHCMP,PARM='C TEST1 VBSRC VBHASH'
//STEPLIB  DD  DSN=&LOADLIB,DISP=SHR
//SRCIN    DD  DSN=&&VBSRC(TEST1),DISP=SHR
//OBJIN    DD  DSN=&&OBJ(TEST1),DISP=SHR
//HASHIN   DD  DSN=&&VBHASH(TEST1),DISP=SHR
// IF (CVB.RC NE 0) THEN
//FAIL4   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  SET MAXCC=12
/*
// ENDIF
//XFB     EXEC PGM=HASHCMP,PARM='C TEST1 FBSRC VBHASH'
//STEPLIB  DD  DSN=&LOADLIB,DISP=SHR
//SRCIN    DD  DSN=&&FBSRC(TEST1),DISP=SHR
//OBJIN    DD  DSN=&&OBJ(TEST1),DISP=SHR
//HASHIN   DD  DSN=&&VBHASH(TEST1),DISP=SHR
// IF (XFB.RC NE 0) THEN
//FAIL5   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  SET MAXCC=12
/*
// ENDIF
//XVB     EXEC PGM=HASHCMP,PARM='C TEST1 VBSRC FBHASH'
//STEPLIB  DD  DSN=&LOADLIB,DISP=SHR
//SRCIN    DD  DSN=&&VBSRC(TEST1),DISP=SHR
//OBJIN    DD  DSN=&&OBJ(TEST1),DISP=SHR
//HASHIN   DD  DSN=&&FBHASH(TEST1),DISP=SHR
// IF (XVB.RC NE 0) THEN
//FAIL6   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  SET MAXCC=12
/*
// ENDIF
//
