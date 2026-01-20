//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Verify INC members present before compile.
//* Objects:
//* +---------+----------------------------------------------+
//* | RUN     | LISTDS on HLQ.LUA.INC                         |
//* +---------+----------------------------------------------+
//UTINCCHK JOB (ACCT),'UT INCCHK',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
//RUN     EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSTSIN  DD *
  LISTDS 'DRBLEZ.LUA.INC' MEMBERS
/*
