//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Unit test tso.cmd (no capture) via LUACMD.
//* Objects:
//* +---------+--------------------------------------------+
//* | RUN     | Execute UTTCMD Lua script via LUACMD       |
//* +---------+--------------------------------------------+
//UTTCMD JOB (ACCT),'UT TSCMD',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
// JCLLIB ORDER=&HLQ..LUA.JCL
//*
//* Run unit test script via LUACMD
//RUN     EXEC PGM=IKJEFT01
//STEPLIB  DD DSN=&HLQ..LUA.LOADLIB,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *,SYMBOLS=JCLONLY
  LUACMD
/*
//LUAIN   DD DSN=&HLQ..LUA.TEST(UTTCMD),DISP=SHR
//LUAOUT  DD SYSOUT=*
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
