//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Lua integration test for tso module via LUAEXEC runner.
//* Objects:
//* +---------+----------------------------------------------+
//* | RUN     | Execute ITTSO Lua script                     |
//* +---------+----------------------------------------------+
//ITTSO  JOB (ACCT),'IT TSO',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
//* Run integration test script
//RUN     EXEC PGM=IKJEFT01
//STEPLIB  DD DSN=&HLQ..LUA.LOADLIB,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  LUACMD
/*
//SYSEXEC DD DSN=&HLQ..LUA.REXX,DISP=SHR
//LUAIN   DD DSN=&HLQ..LUA.TEST(ITTSO),DISP=SHR
//TSOOUT  DD DSN=&&TSOOUT,DISP=(NEW,PASS),
//            UNIT=SYSDA,SPACE=(TRK,(5,5)),
//            RECFM=VB,LRECL=1024,BLKSIZE=0
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
