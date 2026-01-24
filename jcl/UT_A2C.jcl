//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Validate ASM->C OS-linkage parameter passing (non-XPLINK).
//* Objects:
//* +---------+----------------------------------------------+
//* | CCOMP   | Compile A2CCALL into OBJ                     |
//* | CCOMP   | Compile A2CDRVR into OBJ                     |
//* | ACOMP   | Assemble A2CTEST into OBJ                    |
//* | LKED    | Link A2CTEST load module (CEESTART entry)     |
//* | RUNA    | Execute A2CTEST                              |
//* +---------+----------------------------------------------+
//* DDNAMEs:
//* - STEPLIB: &HLQ..LUA.LOADLIB
//* - SYSOUT/SYSPRINT/SYSUDUMP: SYSOUT
//* Expected RC:
//* - CCOMP/ACOMP/LKED/RUNA: 0
//UTA2C   JOB (ACCT),'UT A2C',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
//* ---------------------------------------------------------
//* C compiler PROC (local)
//* ---------------------------------------------------------
//CCOMP   PROC INFILE=,OUTMEM=,HLQ=DRBLEZ
//CC      EXEC PGM=CCNDRVR,REGION=192M,
//         PARM='TERM,RENT,LANGLVL(EXTC99),LONGNAME,NOASM,
//              NOGENASM,NOXPLINK,DEFINE(LUAZ_ZOS)'
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
//         INFILE=&HLQ..LUA.SRC(A2CCALL),
//         OUTMEM=A2CCALL,
//         HLQ=&HLQ
//CC2     EXEC CCOMP,
//         INFILE=&HLQ..LUA.SRC(A2CDRVR),
//         OUTMEM=A2CDRVR,
//         HLQ=&HLQ
//AA1     EXEC ACOMP,
//         INFILE=&HLQ..LUA.ASM(A2CTEST),
//         OUTMEM=A2CTEST,
//         HLQ=&HLQ
//* ---------------------------------------------------------
//* Link-edit and run only after clean compile/assemble
//* ---------------------------------------------------------
//IFCC1   IF (CC1.CC.RC EQ 0) THEN
//IFCC2   IF (CC2.CC.RC EQ 0) THEN
//IFAA    IF (AA1.ASM.RC EQ 0) THEN
//LKED    EXEC PGM=IEWL
//SYSPRINT DD SYSOUT=*
//* Change: use CEESTART with C main to avoid CEEVINT dependency.
//* Problem: CEEVINT missing in LE libraries in this environment.
//* Expected effect: link-edit succeeds without CEEINT/CEEVINT.
//SYSLIB   DD  DISP=SHR,DSN=CEE.SCEELKED
//SYSLIN   DD  *
  INCLUDE OBJLIB(A2CTEST)
  INCLUDE OBJLIB(A2CCALL)
  INCLUDE OBJLIB(A2CDRVR)
* Change: use CEESTART so LE calls C main (A2CDRVR) as entrypoint.
* Expected effect: LE is initialized before ASM subroutine A2CTEST runs.
  ENTRY CEESTART
  NAME A2CTEST(R)
/*
//SYSLMOD  DD  DSN=&HLQ..LUA.LOADLIB(A2CTEST),DISP=SHR
//OBJLIB   DD  DSN=&HLQ..LUA.OBJ,DISP=SHR
//* ---------------------------------------------------------
//* Run test
//* ---------------------------------------------------------
//* Run only on a clean link-edit RC=0.
//* Expected effect: avoid running an old/stale load module after LKED errors.
//IFLKED  IF (LKED.RC EQ 0) THEN
//RUNA    EXEC PGM=A2CTEST
//STEPLIB  DD  DSN=&HLQ..LUA.LOADLIB,DISP=SHR
//SYSOUT   DD  SYSOUT=*
//SYSPRINT DD  SYSOUT=*
//SYSUDUMP DD  SYSOUT=*
//        ENDIF
//        ENDIF
//        ENDIF
//        ENDIF
//*
