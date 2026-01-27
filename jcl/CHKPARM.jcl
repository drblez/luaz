//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Dump PARMLIB members to verify active LNKLST/PROG settings.
//* Objects:
//* +---------+----------------------------------------------+
//* | IEASYS  | Print SYS1.PARMLIB(IEASYS00)                 |
//* | PROG00  | Print SYS1.PARMLIB(PROG00)                   |
//* | LNK00   | Print SYS1.PARMLIB(LNKLST00)                 |
//* Notes:
//* - If IEASYS00 points to other suffixes, rerun with those.
//CHKPARM JOB (ACCT),'CHK PARMLIB',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//IEASYS  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT1   DD DSN=SYS1.PARMLIB(IEASYS00),DISP=SHR
//SYSUT2   DD SYSOUT=*
//PROG00  EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT1   DD DSN=SYS1.PARMLIB(PROG00),DISP=SHR
//SYSUT2   DD SYSOUT=*
//LNK00   EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT1   DD DSN=SYS1.PARMLIB(LNKLST00),DISP=SHR
//SYSUT2   DD SYSOUT=*
