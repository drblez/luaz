//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Unit test for DAIR alloc/free via TSODALC/TSODFRE.
//* DDNAME:
//* - SYSTSPRT: initial SYSOUT target (restored after TSODFRE).
//* Expected RC:
//* - LKED=0, RUN=0.
//* Objects:
//* +---------+----------------------------------------------+
//* | CCOMP   | Compile TSOCALF                              |
//* | ASM1    | Assemble TSODAIR (DAIR wrappers)             |
//* | LKED    | Link TSOCALF + TSODAIR                       |
//* | RUN     | Execute TSOCALF                              |
//* +---------+----------------------------------------------+
//UTTSOAF JOB (ACCT),'UT TSOAF',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
// JCLLIB ORDER=&HLQ..LUA.JCL
//CC1     EXEC CCOMP,INFILE=&HLQ..LUA.SRC(TSOCALF),
//         OUTMEM=TSOCALF,HLQ=&HLQ
//ASM1    EXEC ASMCOMP,INFILE=&HLQ..LUA.ASM(TSODAIR),
//         OUTMEM=TSODAIR,HLQ=&HLQ
//* Change: remove TSOCALF from LOADLIB before linking to LOAD.
//* Problem: multiple datasets can cause ambiguous module resolution.
//* Expected effect: TSOCALF resolves from DRBLEZ.LUA.LOAD only.
//* Impact: LOADLIB copy is deleted to avoid conflicts.
//DELLOAD EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *,SYMBOLS=JCLONLY
  DELETE &HLQ..LUA.LOADLIB(TSOCALF) PURGE
  SET MAXCC=0
/*
//*
//LKED    EXEC PGM=HEWL,PARM='LIST,MAP,XREF,LET,AC=1',REGION=0M
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//* Change: link TSOCALF into DRBLEZ.LUA.LOAD for execution.
//* Problem: need to test run from LOAD dataset instead of LOADLIB.
//* Expected effect: PGM=TSOCALF resolves from DRBLEZ.LUA.LOAD.
//* Impact: requires DRBLEZ.LUA.LOAD to be APF/LNKLST as configured.
//SYSLMOD  DD DSN=&HLQ..LUA.LOAD(TSOCALF),DISP=SHR
//SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR
//         DD DSN=SYS1.LPALIB,DISP=SHR
//         DD DSN=SYS1.LINKLIB,DISP=SHR
//OBJLIB   DD DSN=&HLQ..LUA.OBJ,DISP=SHR
//SYSLIN   DD *
  INCLUDE OBJLIB(TSOCALF)
  INCLUDE OBJLIB(TSODAIR)
  NAME TSOCALF(R)
/*
//*
//RUN     EXEC PGM=TSOCALF,COND=(0,NE,LKED)
//* Change: execute TSOCALF directly to test IKJTSOEV outside TMP.
//* Problem: TMP call path masks direct PGM behavior in this test.
//* Expected effect: TSOCALF runs without IKJEFT01.
//* Impact: CPPL must come from IKJTSOEV; no TMP-provided CPPL.
//* Change: allocate SYSTSPRT as a temporary dataset for DCB inheritance.
//* Problem: SYSOUT SYSTSPRT may not provide stable DCB for DAIR redirect.
//* Expected effect: TSODALC inherits DCB from a real dataset DD.
//* Impact: SYSTSPRT is a temp VB dataset for the duration of RUN.
//SYSTSPRT DD DSN=&&SPRT,DISP=(NEW,PASS),
//            UNIT=SYSDA,SPACE=(TRK,(5,5)),
//            RECFM=VB,LRECL=1024,BLKSIZE=0
//TSOAFLOG DD DSN=&&TLOG,DISP=(NEW,PASS),
//            UNIT=SYSDA,SPACE=(TRK,(5,5)),
//            RECFM=FB,LRECL=133,BLKSIZE=1330
//SYSOUT   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//* Print TSOAFLOG even when RUN abends.
//PRTLOG  EXEC PGM=IEBGENER,COND=EVEN
//SYSUT1  DD DSN=&&TLOG,DISP=(OLD,DELETE),
//            RECFM=FB,LRECL=133,BLKSIZE=1330
//SYSUT2  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN   DD DUMMY
//* Print SYSTSPRT for debug (DAIR source DD).
//PRTSPRT EXEC PGM=IEBGENER,COND=EVEN
//SYSUT1  DD DSN=&&SPRT,DISP=(OLD,DELETE),
//            RECFM=VB,LRECL=1024,BLKSIZE=0
//SYSUT2  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN   DD DUMMY
