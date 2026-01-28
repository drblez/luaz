//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Unit test ds.open_dsn read/write via DSN path.
//* Objects:
//* +---------+--------------------------------------------+
//* | PRECLN  | Delete prior DSN datasets                  |
//* | ALLOCIN | Allocate DSN input dataset                 |
//* | GENIN   | Create input data                          |
//* | ALLOCOT | Allocate DSN output dataset                |
//* | RUN     | Execute UTDSNOP Lua script via LUACMD       |
//* | CLEAN   | Delete DSN datasets                         |
//* +---------+--------------------------------------------+
//UTDSNOP JOB (ACCT),'UT DSNOPEN',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
// JCLLIB ORDER=&HLQ..LUA.JCL
//*
//* Change note: use SYSUID in DSNs for JES in-stream substitution.
//* Reference: jcl/UTDSNOPEN.jcl.md (JES in-stream symbols).
//PRECLN  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//* Reference: jcl/UTDSNOPEN.jcl.md (SYMBOLS=JCLONLY for in-stream data).
//SYSIN   DD *,SYMBOLS=JCLONLY
  DELETE &SYSUID..LUA.TMP.DSNIN PURGE
  DELETE &SYSUID..LUA.TMP.DSNOUT PURGE
  SET MAXCC = 0
/*
//*
//ALLOCIN EXEC PGM=IEFBR14
//DSIN    DD DSN=&SYSUID..LUA.TMP.DSNIN,DISP=(NEW,CATLG,DELETE),
//            DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=0,
//            SPACE=(CYL,(1,1)),UNIT=SYSDA
//*
//GENIN   EXEC PGM=IEBGENER
//SYSUT1  DD *
HELLO
/*
//SYSUT2  DD DSN=&SYSUID..LUA.TMP.DSNIN,DISP=OLD
//SYSPRINT DD SYSOUT=*
//SYSIN   DD DUMMY
//*
//ALLOCOT EXEC PGM=IEFBR14
//DSOUT   DD DSN=&SYSUID..LUA.TMP.DSNOUT,DISP=(NEW,CATLG,DELETE),
//            DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=0,
//            SPACE=(CYL,(1,1)),UNIT=SYSDA
//*
//* Run unit test script via LUACMD
//RUN     EXEC PGM=IKJEFT01,COND=(0,NE,GENIN)
//STEPLIB  DD DSN=&HLQ..LUA.LOADLIB,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//* Change note: enable JCL symbol substitution in SYSTSIN in-stream data.
//* Reference: jcl/UTDSNOPEN.jcl.md (SYMBOLS=JCLONLY in JES in-stream data).
//SYSTSIN  DD *,SYMBOLS=JCLONLY
  LUACMD '&SYSUID..LUA.TMP.DSNIN' '&SYSUID..LUA.TMP.DSNOUT'
/*
//LUAIN   DD DSN=&HLQ..LUA.TEST(UTDSNOP),DISP=SHR
//LUAOUT  DD SYSOUT=*
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
//CLEAN   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//* Reference: jcl/UTDSNOPEN.jcl.md (SYMBOLS=JCLONLY for in-stream data).
//SYSIN   DD *,SYMBOLS=JCLONLY
  DELETE &SYSUID..LUA.TMP.DSNIN PURGE
  DELETE &SYSUID..LUA.TMP.DSNOUT PURGE
  SET MAXCC = 0
/*
