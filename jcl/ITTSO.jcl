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
//CEEDUMP DD SYSOUT=*
//SYSABEND DD SYSOUT=*
//* Change: enable LE TRACE and force CEEDUMP (no SYSMDUMP).
//* Problem: TERMTHDACT(DUMP) attempts IEATDUMP and can skip CEEDUMP.
//* Expected effect: CEEDUMP includes LE trace table and traceback.
//* Impact: CEEDUMP appears in spool with TRACE data for analysis.
//* See: jcl/ITTSO.md#ceeopts-trace
//CEEOPTS DD *
  RPTOPTS(ON),
  RPTSTG(ON),
  TRAP(ON,SPIE),
  ABTERMENC(ABEND),
  TERMTHDACT(UADUMP),
  TRACE(ON,256K,DUMP,LE=1)
/*
//LUAIN   DD DSN=&HLQ..LUA.TEST(ITTSO),DISP=SHR
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
