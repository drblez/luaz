//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Validate ASCII->EBCDIC conversion for FTP-transferred C/ASM.
//* Objects:
//* +---------+----------------------------------------------+
//* | CCOMP   | Compile EBCCHK C program into OBJ            |
//* | ACOMP   | Assemble EBCCHKA ASM program into OBJ         |
//* | LKEDC   | Link-edit EBCCHK load module                  |
//* | LKEDA   | Link-edit EBCCHKA load module                 |
//* | RUNC    | Execute EBCCHK (C output)                     |
//* | RUNA    | Execute EBCCHKA (ASM output via WTO)          |
//* +---------+----------------------------------------------+
//* DDNAMEs:
//* - STEPLIB: &HLQ..LUA.LOADLIB
//* - SYSOUT/SYSPRINT/SYSUDUMP: SYSOUT
//* Expected RC:
//* - CCOMP/ACOMP/LKEDC/LKEDA/RUNC/RUNA: 0
//UTEBCCHK JOB (ACCT),'UT EBCCHK',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
//* ---------------------------------------------------------
//* C compiler PROC (local)
//* ---------------------------------------------------------
//CCOMP   PROC INFILE=,OUTMEM=,HLQ=DRBLEZ
//CC      EXEC PGM=CCNDRVR,REGION=192M,
//         PARM='TERM,RENT,LANGLVL(EXTC99),LONGNAME,NOASM,
//              NOGENASM,DEFINE(LUAZ_ZOS)'
//STEPLIB  DD  DSN=CEE.SCEERUN2,DISP=SHR
//         DD  DSN=CBC.SCCNCMP,DISP=SHR
//         DD  DSN=CEE.SCEERUN,DISP=SHR
//SYSMSGS  DD  DUMMY
//SYSIN    DD  DSN=&INFILE,DISP=SHR
//SYSLIB   DD  DSN=&HLQ..LUA.INC,DISP=SHR
//         DD  DSN=CEE.SCEEH.H,DISP=SHR
//         DD  DSN=CEE.SCEEH.SYS.H,DISP=SHR
//SYSLIN   DD  DSN=&HLQ..LUA.OBJ(&OUTMEM),DISP=SHR
//SYSPRINT DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//SYSCPRT  DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//SYSABEND DD  SYSOUT=*
//CEEDUMP  DD  SYSOUT=*
//SYSUT1   DD  UNIT=SYSALLDA,SPACE=(32000,(30,30)),
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=3200)
//SYSUT5   DD  UNIT=SYSALLDA,SPACE=(32000,(30,30)),
//             DCB=(RECFM=FB,LRECL=3200,BLKSIZE=12800)
//SYSUT6   DD  UNIT=SYSALLDA,SPACE=(32000,(30,30)),
//             DCB=(RECFM=FB,LRECL=3200,BLKSIZE=12800)
//SYSUT7   DD  UNIT=SYSALLDA,SPACE=(32000,(30,30)),
//             DCB=(RECFM=FB,LRECL=3200,BLKSIZE=12800)
//SYSUT8   DD  UNIT=SYSALLDA,SPACE=(32000,(30,30)),
//             DCB=(RECFM=FB,LRECL=3200,BLKSIZE=12800)
//SYSUT9   DD  UNIT=SYSALLDA,SPACE=(32000,(30,30)),
//             DCB=(RECFM=VB,LRECL=137,BLKSIZE=882)
//SYSUT10  DD  SYSOUT=*
//SYSUT14  DD  UNIT=SYSALLDA,SPACE=(32000,(30,30)),
//             DCB=(RECFM=FB,LRECL=3200,BLKSIZE=12800)
//SYSUT16  DD  UNIT=SYSALLDA,SPACE=(32000,(30,30)),
//             DCB=(RECFM=FB,LRECL=3200,BLKSIZE=12800)
//SYSUT17  DD  UNIT=SYSALLDA,SPACE=(32000,(30,30)),
//             DCB=(RECFM=FB,LRECL=3200,BLKSIZE=12800)
//         PEND
//* ---------------------------------------------------------
//* Assembler PROC (local)
//* ---------------------------------------------------------
//ACOMP   PROC INFILE=,OUTMEM=,HLQ=DRBLEZ
//ASM     EXEC PGM=ASMA90,PARM='OBJECT,LIST'
//SYSLIB  DD  DSN=SYS1.MACLIB,DISP=SHR
//        DD  DSN=CEE.SCEEMAC,DISP=SHR
//SYSUT1  DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT2  DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT3  DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSIN   DD  DSN=&INFILE,DISP=SHR
//SYSLIN  DD  DSN=&HLQ..LUA.OBJ(&OUTMEM),DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSOUT  DD  SYSOUT=*
//         PEND
//* ---------------------------------------------------------
//* Compile and assemble
//* ---------------------------------------------------------
//CC1     EXEC CCOMP,
//         INFILE=&HLQ..LUA.SRC(EBCCHK),
//         OUTMEM=EBCCHK,
//         HLQ=&HLQ
//AA1     EXEC ACOMP,
//         INFILE=&HLQ..LUA.ASM(EBCCHKA),
//         OUTMEM=EBCCHKA,
//         HLQ=&HLQ
//* ---------------------------------------------------------
//* Link-edit C program
//* ---------------------------------------------------------
//LKEDC   EXEC PGM=IEWL,COND=(4,LT)
//SYSPRINT DD SYSOUT=*
//SYSLIB   DD  DISP=SHR,DSN=CEE.SCEELKED
//SYSLIN   DD  DSN=&HLQ..LUA.OBJ(EBCCHK),DISP=SHR
//SYSLMOD  DD  DSN=&HLQ..LUA.LOADLIB(EBCCHK),DISP=SHR
//SYSIN    DD  *
  NAME EBCCHK(R)
/*
//* ---------------------------------------------------------
//* Link-edit ASM program
//* ---------------------------------------------------------
//LKEDA   EXEC PGM=IEWL,COND=(4,LT)
//SYSPRINT DD SYSOUT=*
//SYSLIB   DD  DISP=SHR,DSN=SYS1.MACLIB
//SYSLIN   DD  DSN=&HLQ..LUA.OBJ(EBCCHKA),DISP=SHR
//SYSLMOD  DD  DSN=&HLQ..LUA.LOADLIB(EBCCHKA),DISP=SHR
//SYSIN    DD  *
  NAME EBCCHKA(R)
/*
//* ---------------------------------------------------------
//* Run C and ASM checks
//* ---------------------------------------------------------
//RUNC    EXEC PGM=EBCCHK,COND=(4,LT)
//STEPLIB  DD  DSN=&HLQ..LUA.LOADLIB,DISP=SHR
//SYSOUT   DD  SYSOUT=*
//SYSPRINT DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//RUNA    EXEC PGM=EBCCHKA,COND=(4,LT)
//STEPLIB  DD  DSN=&HLQ..LUA.LOADLIB,DISP=SHR
//SYSOUT   DD  SYSOUT=*
//SYSPRINT DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//*
