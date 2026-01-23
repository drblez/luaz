//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Integration test for LUACMD -> LUAEXEC MODE=TSO propagation.
//* Objects:
//* +---------+----------------------------------------------+
//* | RUN     | Execute ITLUACMD Lua script via LUACMD        |
//* +---------+----------------------------------------------+
//* DDNAMEs:
//* - STEPLIB: &HLQ..LUA.LOADLIB (LUAEXEC/LUACMD)
//* - LUAIN: &HLQ..LUA.TEST(ITLUACMD)
//* - SYSTSPRT/SYSOUT/SYSPRINT/SYSUDUMP: SYSOUT
//* Expected RC:
//* - RUN: 0
//ITLUACMD JOB (ACCT),'IT LUACMD',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
//* Run integration test script
//RUN     EXEC PGM=IKJEFT01
//STEPLIB  DD DSN=&HLQ..LUA.LOADLIB,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  LUACMD MODE=TSO
/*
//SYSEXEC DD DSN=&HLQ..LUA.REXX,DISP=SHR
//LUAIN   DD DSN=&HLQ..LUA.TEST(ITLUACMD),DISP=SHR
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
