//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Unit test ds.info via LUACMD.
//* Objects:
//* +---------+--------------------------------------------+
//* | ALLOC   | Allocate dataset for info                 |
//* | RUN     | Execute UTDSINF Lua script via LUACMD      |
//* | CLEAN   | Delete dataset                             |
//* +---------+--------------------------------------------+
//UTDSINF JOB (ACCT),'UT DSINF',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
// JCLLIB ORDER=&HLQ..LUA.JCL
//*
//ALLOC   EXEC PGM=IEFBR14
//DSINF   DD DSN=&SYSUID..LUA.TMP.DSINF,DISP=(MOD,CATLG,DELETE),
//            DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=0,
//            SPACE=(CYL,(1,1)),UNIT=SYSDA
//*
//* Run unit test script via LUACMD
//RUN     EXEC PGM=IKJEFT01,COND=(0,NE,ALLOC)
//STEPLIB  DD DSN=&HLQ..LUA.LOADLIB,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *,SYMBOLS=JCLONLY
  LUACMD '&SYSUID..LUA.TMP.DSINF'
/*
//LUAIN   DD DSN=&HLQ..LUA.TEST(UTDSINF),DISP=SHR
//LUAOUT  DD SYSOUT=*
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
//CLEAN   EXEC PGM=IEFBR14,COND=(0,LE,RUN)
//DSINF   DD DSN=&SYSUID..LUA.TMP.DSINF,DISP=(MOD,DELETE,DELETE),
//            DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=0,
//            SPACE=(CYL,(1,1)),UNIT=SYSDA
//*
