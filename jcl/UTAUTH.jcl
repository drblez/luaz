//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Check AUTHPGM/AUTHCMD and APF list sources.
//* Objects:
//* +---------+----------------------------------------------+
//* | CONS    | Issue operator displays (D IKJTSO / D PROG)   |
//* | P0      | Print SYS1.PARMLIB(IKJTSO00)                  |
//* | PXX     | Print SYS1.PARMLIB(IKJTSO&TSOXX)              |
//* +---------+----------------------------------------------+
//* Notes:
//* - CONSOLE commands require authority; if denied, CONS will show errors.
//* - Change TSOXX if D IKJTSO reports a different suffix.
//UTAUTH  JOB (ACCT),'UT AUTH',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET TSOXX=00
//*
//CONS    EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSTSIN  DD *
  PROFILE MSGID
  CONSOLE 'D IKJTSO'
  CONSOLE 'D PROG,APF'
/*
//*
//P0      EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT1   DD DSN=SYS1.PARMLIB(IKJTSO00),DISP=SHR
//SYSUT2   DD SYSOUT=*
//*
//PXX     EXEC PGM=IEBGENER
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT1   DD DSN=SYS1.PARMLIB(IKJTSO&TSOXX),DISP=SHR
//SYSUT2   DD SYSOUT=*
