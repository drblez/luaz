//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: List members of SYS1.MACLIB and SYS1.MODGEN.
//* Objects:
//* +---------+----------------------------------------------+
//* | MACLIB  | List SYS1.MACLIB members                      |
//* | MODGEN  | List SYS1.MODGEN members                      |
//* +---------+----------------------------------------------+
//UTIKJLS JOB (ACCT),'UT IKJ LIST',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//MACLIB  EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  LISTDS 'SYS1.MACLIB' MEMBERS
/*
//MODGEN  EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  LISTDS 'SYS1.MODGEN' MEMBERS
/*
