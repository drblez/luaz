//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Incremental compare/assemble/update PROC for BUILDINC.
//* Objects:
//* +---------+----------------------------------------------+
//* | ACOMP   | compare hash -> assemble -> update hash      |
//* +---------+----------------------------------------------+
//ACOMP PROC INFILE=,OUTMEM=
//HCMP   EXEC PGM=HASHCMP,PARM='C &OUTMEM &ASMSRC &ASMHPDS'
//STEPLIB DD  DSN=&LOADLIB,DISP=SHR
//SRCIN  DD  DSN=&ASMSRC(&OUTMEM),DISP=SHR
//OBJIN  DD  DSN=&HLQ..LUA.OBJ(&OUTMEM),DISP=SHR
//HASHIN DD  DSN=&ASMHPDS(&OUTMEM),DISP=SHR
//ASM    EXEC PGM=ASMA90,PARM='OBJECT,LIST',COND=(4,NE,HCMP)
//SYSLIB DD  DSN=SYS1.MACLIB,DISP=SHR
//       DD  DSN=CEE.SCEEMAC,DISP=SHR
//SYSUT1 DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT2 DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSUT3 DD  UNIT=SYSALLDA,SPACE=(CYL,(1,1))
//SYSIN  DD  DSN=&INFILE,DISP=SHR
//SYSLIN DD  DSN=&HLQ..LUA.OBJ(&OUTMEM),DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSOUT DD SYSOUT=*
//* Change: delete OBJ member on any nonzero ASM RC.
//* Problem: failed assemble can leave stale object for link-edit.
//* Expected effect: force rebuild instead of reusing bad OBJ.
//DEL    EXEC PGM=IDCAMS,COND=((4,NE,HCMP),(0,EQ,ASM))
//SYSPRINT DD SYSOUT=*
//SYSIN  DD DSN=&HLQ..LUA.CTL(&OUTMEM),DISP=SHR
//HU     EXEC PGM=HASHCMP,
//        COND=((4,NE,HCMP),(0,NE,ASM)),
//        PARM='U &OUTMEM &ASMSRC &ASMHPDS'
//STEPLIB DD  DSN=&LOADLIB,DISP=SHR
//SRCIN  DD  DSN=&ASMSRC(&OUTMEM),DISP=SHR
//HASHOUT DD DSN=&ASMHPDS(&OUTMEM),DISP=SHR
//PEND   PEND
