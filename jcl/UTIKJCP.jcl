//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Dump IKJCPPL macro source from SYS1.MACLIB.
//* Objects:
//* +---------+----------------------------------------------+
//* | CPPL    | Print IKJCPPL macro source                   |
//* +---------+----------------------------------------------+
//UTIKJCP JOB (ACCT),'UT IKJCPPL',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//CPPL   EXEC PGM=IEBGENER
//SYSUT1   DD DSN=SYS1.MACLIB(IKJCPPL),DISP=SHR
//SYSUT2   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
