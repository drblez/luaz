//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Unit test ds.rename via LUACMD.
//* Objects:
//* +---------+--------------------------------------------+
//* | PRENEW  | Ensure target dataset is absent            |
//* | ALLOC   | Allocate source dataset                    |
//* | RUN     | Execute UTDSREN Lua script via LUACMD      |
//* | CLEAN   | Delete datasets if they still exist        |
//* +---------+--------------------------------------------+
//UTDSREN JOB (ACCT),'UT DSREN',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
// JCLLIB ORDER=&HLQ..LUA.JCL
//*
//PRENEW  EXEC PGM=IEFBR14
//DSNEW   DD DSN=&SYSUID..LUA.TMP.DSREN2,DISP=(MOD,DELETE,DELETE),
//            DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=0,
//            SPACE=(CYL,(1,1)),UNIT=SYSDA
//*
//ALLOC   EXEC PGM=IEFBR14
//DSOLD   DD DSN=&SYSUID..LUA.TMP.DSREN1,DISP=(MOD,CATLG,DELETE),
//            DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=0,
//            SPACE=(CYL,(1,1)),UNIT=SYSDA
//*
//* Run unit test script via LUACMD
//RUN     EXEC PGM=IKJEFT01,COND=(0,NE,ALLOC)
//STEPLIB  DD DSN=&HLQ..LUA.LOADLIB,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *,SYMBOLS=JCLONLY
  LUACMD '&SYSUID..LUA.TMP.DSREN1' '&SYSUID..LUA.TMP.DSREN2'
/*
//LUAIN   DD DSN=&HLQ..LUA.TEST(UTDSREN),DISP=SHR
//LUAOUT  DD SYSOUT=*
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
//CLEAN   EXEC PGM=IEFBR14,COND=(0,LE,RUN)
//DSNEW   DD DSN=&SYSUID..LUA.TMP.DSREN2,DISP=(MOD,DELETE,DELETE),
//            DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=0,
//            SPACE=(CYL,(1,1)),UNIT=SYSDA
//DSOLD   DD DSN=&SYSUID..LUA.TMP.DSREN1,DISP=(MOD,DELETE,DELETE),
//            DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=0,
//            SPACE=(CYL,(1,1)),UNIT=SYSDA
//*
