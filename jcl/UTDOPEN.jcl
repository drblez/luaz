//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Unit test ds.open_dd read/write via DDNAME.
//* Objects:
//* +---------+--------------------------------------------+
//* | ALLOC   | Allocate temp PS datasets                  |
//* | GENIN   | Create input data                          |
//* | UTBLD   | Compile DSUT/DS and link into &HLQ..LUA.LOAD|
//* | RUN     | Execute DSUT with DDNAMEs                  |
//* +---------+--------------------------------------------+
//UTDOPEN JOB (ACCT),'UT DSOPEN',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
// JCLLIB ORDER=&HLQ..LUA.JCL
//*
//ALLOC   EXEC PGM=IEFBR14
//DSOUT   DD DSN=&&DSOUT,DISP=(NEW,PASS),
//            DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=0,
//            SPACE=(CYL,(1,1)),UNIT=SYSDA
//*
//GENIN   EXEC PGM=IEBGENER
//SYSUT1  DD *
HELLO
/*
//SYSUT2  DD DSN=&&DSIN,DISP=(NEW,PASS),
//            DSORG=PS,RECFM=FB,LRECL=80,BLKSIZE=0,
//            SPACE=(CYL,(1,1)),UNIT=SYSDA
//SYSPRINT DD SYSOUT=*
//SYSIN   DD DUMMY
//*
//UTBLD  EXEC UTBLD,HLQ=&HLQ,
//         IN1MEM=DSUT,OUT1=DSUT,
//         USE2=1,IN2MEM=DS,OUT2=DS,
//         USE3=0,IN3MEM=ZZZ2,OUT3=ZZZ2,
//         USE4=0,IN4MEM=ZZZ3,OUT4=ZZZ3,
//         LMEM=DSUT
//LKED.SYSLIN DD *
  INCLUDE OBJLIB(DSUT)
  INCLUDE OBJLIB(DS)
  NAME DSUT(R)
/*
//*
//RUN     EXEC PGM=DSUT,COND=(0,NE,UTBLD.LKED)
//STEPLIB DD DSN=&HLQ..LUA.LOAD,DISP=SHR
//DSIN    DD DSN=&&DSIN,DISP=(OLD,DELETE)
//DSOUT   DD DSN=&&DSOUT,DISP=(OLD,PASS)
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
//VERIFY  EXEC PGM=DSUT,PARM='VERIFY',COND=(0,NE,RUN)
//STEPLIB DD DSN=&HLQ..LUA.LOAD,DISP=SHR
//DDCHECK DD DSN=&&DSOUT,DISP=(OLD,DELETE)
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
