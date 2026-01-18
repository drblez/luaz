//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Common UT compile+link PROC to avoid stale OBJ usage.
//* Objects:
//* +--------+----------------------------------------------+
//* | UTBLD  | Compile up to 4 sources and link one program |
//* +--------+----------------------------------------------+
//UTBLD PROC HLQ=DRBLEZ,IN1=,OUT1=,IN2=NONE,OUT2=NONE,IN3=NONE,OUT3=NONE,
//             IN4=NONE,OUT4=NONE,LMEM=
//CC1    EXEC CCOMP,INFILE=&IN1,OUTMEM=&OUT1,HLQ=&HLQ
// IF (&IN2 NE NONE) THEN
//CC2    EXEC CCOMP,INFILE=&IN2,OUTMEM=&OUT2,HLQ=&HLQ
// ELSE
//CC2    EXEC PGM=IEFBR14
// ENDIF
// IF (&IN3 NE NONE) THEN
//CC3    EXEC CCOMP,INFILE=&IN3,OUTMEM=&OUT3,HLQ=&HLQ
// ELSE
//CC3    EXEC PGM=IEFBR14
// ENDIF
// IF (&IN4 NE NONE) THEN
//CC4    EXEC CCOMP,INFILE=&IN4,OUTMEM=&OUT4,HLQ=&HLQ
// ELSE
//CC4    EXEC PGM=IEFBR14
// ENDIF
//LKED   EXEC PGM=HEWL,PARM='LIST,MAP,XREF,LET',REGION=0M,
//         COND=((0,NE,CC1),(0,NE,CC2),(0,NE,CC3),(0,NE,CC4))
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSLMOD  DD DSN=&HLQ..LUA.LOAD(&LMEM),DISP=SHR
//SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR
//OBJLIB   DD DSN=&HLQ..LUA.OBJ,DISP=SHR
//SYSLIN   DD DUMMY
//         PEND
