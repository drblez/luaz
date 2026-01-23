//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: List externals/entries for TSONATV object member.
//* Objects:
//* +---------+----------------------------------------------+
//* | LKED    | Binder listing for TSONATV object            |
//* +---------+----------------------------------------------+
//LISTTSON JOB (ACCT),'LIST TSON',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//LKED     EXEC PGM=HEWL,PARM='LIST,MAP,XREF,LET'
//SYSPRINT DD  SYSOUT=*
//SYSUT1   DD  UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSLMOD  DD  DSN=&&TEMPMOD,UNIT=SYSDA,SPACE=(TRK,(1,1,1)),
//             DISP=(NEW,PASS),DSNTYPE=LIBRARY
//SYSLIB   DD  DSN=CEE.SCEELKED,DISP=SHR
//         DD  DSN=SYS1.LPALIB,DISP=SHR
//OBJLIB   DD  DSN=DRBLEZ.LUA.OBJ,DISP=SHR
//SYSLIN   DD  *
  INCLUDE OBJLIB(TSONATV)
  NAME TSONATV(R)
/*
//
