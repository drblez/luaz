//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Unit test ds.tmpname via LUACMD.
//* Objects:
//* +---------+--------------------------------------------+
//* | RUN     | Execute UTDSTMP Lua script via LUACMD       |
//* +---------+--------------------------------------------+
//UTDSTMP JOB (ACCT),'UT DSTMP',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
// JCLLIB ORDER=&HLQ..LUA.JCL
//*
//* Run unit test script via LUACMD
//RUN     EXEC PGM=IKJEFT01
//STEPLIB  DD DSN=&HLQ..LUA.LOADLIB,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  LUACMD
/*
//LUAIN   DD DSN=&HLQ..LUA.TEST(UTDSTMP),DISP=SHR
//LUAOUT  DD SYSOUT=*
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
