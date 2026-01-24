//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Incremental compare/compile/update PROC for BUILDINC.
//* Objects:
//* +---------+----------------------------------------------+
//* | ICOMP   | compare hash -> compile -> update hash       |
//* +---------+----------------------------------------------+
//ICOMP PROC INFILE=,OUTMEM=
//HCMP    EXEC PGM=HASHCMP,PARM='C &OUTMEM &SRCPDS &HASHPDS'
//STEPLIB  DD  DSN=&LOADLIB,DISP=SHR
//SRCIN    DD  DSN=&SRCPDS(&OUTMEM),DISP=SHR
//OBJIN    DD  DSN=&HLQ..LUA.OBJ(&OUTMEM),DISP=SHR
//HASHIN   DD  DSN=&HASHPDS(&OUTMEM),DISP=SHR
//* Change: move CCNDRVR options into OPTFILE (CTL member).
//* Problem: long EXEC PARM caused IEFC642 length errors in BUILDINC.
//* Expected effect: stable JCL parsing and richer compiler listings.
//* See: jcl/ICOMP.md#cc-options
//CC      EXEC PGM=CCNDRVR,REGION=192M,
//         COND=(4,NE,HCMP),
//         PARM='OPTFILE(DD:CCOPTS)'
//STEPLIB  DD  DSN=CEE.SCEERUN2,DISP=SHR
//        DD  DSN=CBC.SCCNCMP,DISP=SHR
//        DD  DSN=CEE.SCEERUN,DISP=SHR
//SYSMSGS  DD  DUMMY
//CCOPTS   DD  DSN=&HLQ..LUA.CTL(CCOPTS),DISP=SHR
//SYSIN    DD  DSN=&INFILE,DISP=SHR
//SYSLIB   DD  DSN=&HLQ..LUA.INC,DISP=SHR
//        DD  DSN=CEE.SCEEH.H,DISP=SHR
//        DD  DSN=CEE.SCEEH.SYS.H,DISP=SHR
//SYSLIN   DD  DSN=&HLQ..LUA.OBJ(&OUTMEM),DISP=SHR
//SYSPRINT DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//SYSCPRT  DD  SYSOUT=*
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
//* Change: allow HCMP RC=4 to propagate; ftp_submit.sh decides acceptance.
//* Problem: local MAXCC reset masked non-HCMP RC handling.
//* Expected effect: job RC remains 4 for rebuild-only runs.
//* Impact: tooling decides if RC=4 is acceptable (HCMP-only).
//* Change: delete OBJ member on any nonzero compile RC.
//* Problem: failed compile can leave stale object for link-edit.
//* Expected effect: force rebuild instead of reusing bad OBJ.
//DEL     EXEC PGM=IDCAMS,COND=((4,NE,HCMP),(0,EQ,CC))
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DSN=&HLQ..LUA.CTL(&OUTMEM),DISP=SHR
//HU      EXEC PGM=HASHCMP,
//         COND=((4,NE,HCMP),(0,NE,CC)),
//         PARM='U &OUTMEM &SRCPDS &HASHPDS'
//STEPLIB  DD  DSN=&LOADLIB,DISP=SHR
//SRCIN    DD  DSN=&SRCPDS(&OUTMEM),DISP=SHR
//HASHOUT  DD  DSN=&HASHPDS(&OUTMEM),DISP=SHR
//PEND    PEND
