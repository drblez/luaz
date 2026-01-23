//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Inspect SYS1.LINKLIB dataset attributes.
//* Objects:
//* +---------+----------------------------------------------+
//* | LISTDS  | Show DSORG/DSNTYPE and attributes            |
//* +---------+----------------------------------------------+
//UTLNKDS JOB (ACCT),'UT LINKLIB',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//S1     EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  LISTDS 'SYS1.LINKLIB'
/*
