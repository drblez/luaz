//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Assemble a HLASM source into OBJ.
//* Objects:
//* +---------+----------------------------------------------+
//* | ASMCOMP | Assemble one member into LUA.OBJ             |
//* +---------+----------------------------------------------+
//ASMCOMP PROC INFILE=,OUTMEM=,HLQ=DRBLEZ
//ASM     EXEC PGM=ASMA90,PARM='OBJECT'
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
