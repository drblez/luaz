//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Copy TSOAUTH from DRBLEZ.LUA.LOAD into SYS1.LINKLIB.
//* Objects:
//* +---------+----------------------------------------------+
//* | COPY    | IEBCOPY copy TSOAUTH to SYS1.LINKLIB         |
//* +---------+----------------------------------------------+
//COPTLNK JOB (ACCT),'COPY TSOAUTH',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
//COPY    EXEC PGM=IEBCOPY
//SYSPRINT DD SYSOUT=*
//SYSUT3  DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//INLIB   DD DSN=&HLQ..LUA.LOAD,DISP=SHR
//OUTLIB  DD DSN=SYS1.LINKLIB,DISP=SHR
//SYSIN   DD *
  COPY INDD=INLIB,OUTDD=OUTLIB
  SELECT MEMBER=(TSOAUTH)
/*
