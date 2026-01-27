//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Verify LUACMD command resolution via LNKLST (no STEPLIB).
//* Objects:
//* +---------+----------------------------------------------+
//* | RUN     | Execute LUACMD under IKJEFT01                |
//* +---------+----------------------------------------------+
//* Expected:
//* - LUACMD is resolved as a command processor (no INVALID KEYWORD).
//CHKCMD  JOB (ACCT),'CHK LUACMD',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
//* Run LUACMD without STEPLIB to force LNKLST resolution.
//RUN     EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  LUACMD LUZTRACE ARG1 'ARG TWO'
/*
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//*
