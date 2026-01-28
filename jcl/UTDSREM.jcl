//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Unit test ds.remove via LUACMD.
//* Objects:
//* +---------+--------------------------------------------+
//* | ALLOC   | Allocate dataset to remove                |
//* | RUN     | Execute UTDSREM Lua script via LUACMD      |
//* | CLEAN   | Delete dataset if it still exists         |
//* +---------+--------------------------------------------+
//UTDSREM JOB (ACCT),'UT DSREM',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
// JCLLIB ORDER=&HLQ..LUA.JCL
//*
//ALLOC   EXEC PGM=IEFBR14
//DSREM   DD DSN=&SYSUID..LUA.TMP.DSREM,DISP=(MOD,CATLG,DELETE),
//            DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=0,
//            SPACE=(CYL,(1,1)),UNIT=SYSDA
//*
//* Run unit test script via LUACMD
//RUN     EXEC PGM=IKJEFT01,COND=(0,NE,ALLOC)
//STEPLIB  DD DSN=&HLQ..LUA.LOADLIB,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *,SYMBOLS=JCLONLY
  LUACMD '&SYSUID..LUA.TMP.DSREM'
/*
//LUAIN   DD DSN=&HLQ..LUA.TEST(UTDSREM),DISP=SHR
//LUAOUT  DD SYSOUT=*
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
//CLEAN   EXEC PGM=IEFBR14,COND=(0,LE,RUN)
//DSREM   DD DSN=&SYSUID..LUA.TMP.DSREM,DISP=(MOD,DELETE,DELETE),
//            DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=0,
//            SPACE=(CYL,(1,1)),UNIT=SYSDA
//*
