//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Check TSO/E authorization lists and LNKLST without LLA.
//* Objects:
//* +---------+----------------------------------------------+
//* | RUN     | Issue operator displays under IKJEFT01       |
//* +---------+----------------------------------------------+
//* Expected:
//* - D IKJTSO shows AUTHCMD/AUTHTSF/AUTHPGM lists.
//* - D PROG,LNKLST shows active linklist concatenation.
//* - D PROG,APF shows APF list for load libs.
//CHKTSO  JOB (ACCT),'CHK TSO ENV',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//RUN     EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  OPERATOR 'D IKJTSO,AUTHCMD'
  OPERATOR 'D IKJTSO,AUTHTSF'
  OPERATOR 'D IKJTSO,AUTHPGM'
  OPERATOR 'D PROG,LNKLST'
  OPERATOR 'D PROG,APF'
/*
//SYSOUT  DD SYSOUT=*
//*
