//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Minimal IRXEXEC + LUTSO test without Lua.
//* Objects:
//* +---------+----------------------------------------------+
//* | CCOMP   | Compile TSOLUT                               |
//* | LKED    | Link TSOLUT                                  |
//* | RUN     | Execute TSOLUT                               |
//* +---------+----------------------------------------------+
//UTTSOX  JOB (ACCT),'UT TSOX',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
// JCLLIB ORDER=&HLQ..LUA.JCL
//CC      EXEC CCOMP,INFILE=&HLQ..LUA.SRC(TSOLUT),
//         OUTMEM=TSOLUT,HLQ=&HLQ
//* 
//LKED    EXEC PGM=HEWL,PARM='LIST,MAP,XREF,LET',REGION=0M
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSLMOD  DD DSN=&HLQ..LUA.LOAD(TSOLUT),DISP=SHR
//SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR
//         DD DSN=SYS1.LPALIB,DISP=SHR
//OBJLIB   DD DSN=&HLQ..LUA.OBJ,DISP=SHR
//SYSLIN   DD *
  INCLUDE OBJLIB(TSOLUT)
  NAME TSOLUT(R)
/*
//* 
//RUN     EXEC PGM=TSOLUT,COND=(0,NE,LKED)
//STEPLIB  DD DSN=&HLQ..LUA.LOAD,DISP=SHR
//         DD DSN=SYS1.LPALIB,DISP=SHR
//SYSEXEC  DD DSN=&HLQ..LUA.REXX,DISP=SHR
//TSOOUT   DD DSN=&&TSOOUT,DISP=(NEW,PASS),
//            UNIT=SYSDA,SPACE=(TRK,(5,5)),
//            RECFM=VB,LRECL=1024,BLKSIZE=0
//SYSTSIN  DD DUMMY
//SYSTSPRT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
