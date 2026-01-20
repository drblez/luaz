//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Unit test for IRXEXEC minimal invocation.
//* Objects:
//* +---------+----------------------------------------------+
//* | REXXDD  | Allocate temp SYSEXEC PDS with HELLO exec    |
//* | IEBGEN  | Populate HELLO exec                          |
//* | CC      | Compile IRXUT                                |
//* | LKED    | Link IRXUT                                   |
//* | RUN     | Execute IRXUT                                |
//* +---------+----------------------------------------------+
//UTIRX   JOB (ACCT),'UT IRXEXEC',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
// JCLLIB ORDER=&HLQ..LUA.JCL
//REXXDD  EXEC PGM=IEFBR14
//SYSEXEC DD DSN=&&REXX,DISP=(NEW,PASS),UNIT=SYSDA,SPACE=(TRK,(1,1,1)),
//            DCB=(DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=3120)
//*
//IEBGEN  EXEC PGM=IEBGENER
//SYSUT1   DD *
ARG N
IF N = '' THEN N = 1
SAY 'LUZ00013 IRXEXEC UT HELLO ARG=' N
RETURN N
/*
//SYSUT2   DD DSN=&&REXX(HELLO),DISP=OLD
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//*
//CC      EXEC CCOMP,INFILE=&HLQ..LUA.SRC(IRXUT),OUTMEM=IRXUT,HLQ=&HLQ
//*
//LKED    EXEC PGM=HEWL,PARM='LIST,MAP,XREF,LET',REGION=0M
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSLMOD  DD DSN=&HLQ..LUA.LOAD(IRXUT),DISP=SHR
//SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR
//         DD DSN=SYS1.LPALIB,DISP=SHR
//OBJLIB   DD DSN=&HLQ..LUA.OBJ,DISP=SHR
//SYSLIN   DD *
  INCLUDE OBJLIB(IRXUT)
  NAME IRXUT(R)
/*
//*
//RUN     EXEC PGM=IRXUT,COND=(0,NE,LKED)
//STEPLIB  DD DSN=&HLQ..LUA.LOAD,DISP=SHR
//         DD DSN=SYS1.LPALIB,DISP=SHR
//SYSEXEC  DD DSN=&&REXX,DISP=OLD
//SYSTSIN  DD DUMMY
//SYSTSPRT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
