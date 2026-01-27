//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Compile, link, run the TSO C TIME example, and print output.
//* DDNAME inputs:
//* - &HLQ..LUA.SRC(TSOCEX) source
//* - &HLQ..LUA.OBJ          object output
//* - &HLQ..LUA.LOAD         load output
//* DDNAME outputs: SYSPRINT/SYSOUT/SYSCPRT/SYSUDUMP/CEEDUMP, SYSUT2 (print)
//* Expected RC: CC<=4, LKED<=4, RUN=0
//TSOCEX  JOB (ACCT),'TSO C EX',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//* Change: remove &HLQ symbols to avoid unresolved dataset names in SYSTSIN.
//* Problem: &HLQ is not resolved inside IKJEFT01 command stream.
//* Expected effect: CALL and DD statements use absolute DSNs.
//* Impact: job is tied to DRBLEZ HLQ until parameterized again.
// JCLLIB ORDER=DRBLEZ.LUA.JCL
//*
//* Change: split EXEC parms to avoid JCL line truncation.
//* Problem: long EXEC line caused IEFC618I/IEFC621I.
//* Expected effect: CCOMP step receives full INFILE/OUTMEM/HLQ parms.
//* Impact: compile step executes with correct parameters.
//CC      EXEC CCOMP,INFILE=DRBLEZ.LUA.SRC(TSOCEX),
//             OUTMEM=TSOCEX,HLQ=DRBLEZ
//*
//* Change: drop referback to PROC step to avoid IEF645I.
//* Problem: referback in COND to PROC step caused invalid referback.
//* Expected effect: LKED runs only when previous RC < 4.
//* Impact: uses global COND without step reference.
//LKED    EXEC PGM=IEWL,COND=(4,LT)
//SYSPRINT DD SYSOUT=*
//* Change: add C runtime and TSO service libraries for unresolved symbols.
//* Problem: LKED RC=8 unresolved __dynalloc/__dynfree/IKJEFTSR/IKJTSOEV.
//* Expected effect: binder resolves C runtime and TSO service entry points.
//* Impact: additional SYSLIB concatenation for link-edit.
//SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR
//         DD DSN=CEE.SCEELKEX,DISP=SHR
//         DD DSN=CBC.SCLBDLL,DISP=SHR
//         DD DSN=SYS1.LPALIB,DISP=SHR
//         DD DSN=SYS1.LINKLIB,DISP=SHR
//SYSLIN   DD DSN=DRBLEZ.LUA.OBJ(TSOCEX),DISP=SHR
//SYSLMOD  DD DSN=DRBLEZ.LUA.LOAD(TSOCEX),DISP=SHR
//*
//* Change: drop step referback in COND to avoid IEF645I.
//* Problem: referback in COND triggered invalid referback errors.
//* Expected effect: RUN depends on prior RC without step reference.
//* Impact: job skips RUN when any earlier RC >= 4.
//RUN     EXEC PGM=IKJEFT01,COND=(4,LT)
//SYSTSIN  DD *
  CALL 'DRBLEZ.LUA.LOAD(TSOCEX)'
/*
//* Change: allocate SYSTSPRT to a dataset member for program readback.
//* Problem: SYSOUT cannot be reopened by the C example for read.
//* Expected effect: TIME output is written to &HLQ..LUA.CTL(TIMEOUT@).
//* Impact: requires existing PDS/PDSE and correct RECFM/LRECL.
//SYSTSPRT DD DSN=DRBLEZ.LUA.CTL(TIMEOUT@),DISP=OLD
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//CEEDUMP  DD SYSOUT=*
//* Print captured output member to spool for quick review.
//* Change: always print output to help debug failures.
//* Problem: prior COND skipped PRTTIME when RUN failed.
//* Expected effect: TIMEOUT@ contents are available even on errors.
//* Impact: SYSUT2 may include error diagnostics.
//PRTTIME EXEC PGM=IEBGENER,COND=EVEN
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD DSN=DRBLEZ.LUA.CTL(TIMEOUT@),DISP=SHR
//SYSUT2   DD SYSOUT=*
//SYSIN    DD DUMMY
