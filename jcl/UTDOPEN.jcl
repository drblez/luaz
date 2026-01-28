//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Unit test ds.open_dd read/write via DDNAME.
//* Objects:
//* +---------+--------------------------------------------+
//* | ALLOC   | Allocate temp PS datasets                  |
//* | GENIN   | Create input data                          |
//* | RUN     | Execute UTDOPEN Lua script via LUACMD      |
//* +---------+--------------------------------------------+
//UTDOPEN JOB (ACCT),'UT DSOPEN',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
// JCLLIB ORDER=&HLQ..LUA.JCL
//*
//ALLOC   EXEC PGM=IEFBR14
//DSOUT   DD DSN=&&DSOUT,DISP=(NEW,PASS),
//            DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=0,
//            SPACE=(CYL,(1,1)),UNIT=SYSDA
//*
//GENIN   EXEC PGM=IEBGENER
//SYSUT1  DD *
HELLO
/*
//SYSUT2  DD DSN=&&DSIN,DISP=(NEW,PASS),
//            DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=0,
//            SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSPRINT DD SYSOUT=*
//SYSIN   DD DUMMY
//*
//* Run unit test script via LUACMD
//RUN     EXEC PGM=IKJEFT01,COND=(0,NE,GENIN)
//STEPLIB  DD DSN=&HLQ..LUA.LOADLIB,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  LUACMD
/*
//LUAIN   DD DSN=&HLQ..LUA.TEST(UTDOPEN),DISP=SHR
//DSIN    DD DSN=&&DSIN,DISP=(OLD,DELETE)
//DSOUT   DD DSN=&&DSOUT,DISP=(OLD,DELETE)
//LUAOUT  DD SYSOUT=*
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
