//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Common UT compile+link PROC to avoid stale OBJ usage.
//* Objects:
//* +--------+----------------------------------------------+
//* | UTBLD  | Compile up to 4 sources and link one program |
//* +--------+----------------------------------------------+
//UTBLD PROC HLQ=DRBLEZ,IN1MEM=,OUT1=,
//             USE2=0,IN2MEM=ZZZ1,OUT2=ZZZ1,
//             USE3=0,IN3MEM=ZZZ2,OUT3=ZZZ2,
//             USE4=0,IN4MEM=ZZZ3,OUT4=ZZZ3,
//             LMEM=
//CC1    EXEC CCOMP,INFILE=&HLQ..LUA.SRC(&IN1MEM),OUTMEM=&OUT1,HLQ=&HLQ
// IF (&USE2 EQ 1) THEN
//CC2    EXEC CCOMP,INFILE=&HLQ..LUA.SRC(&IN2MEM),OUTMEM=&OUT2,HLQ=&HLQ
// ELSE
//CC2    EXEC PGM=IEFBR14
// ENDIF
// IF (&USE3 EQ 1) THEN
//CC3    EXEC CCOMP,INFILE=&HLQ..LUA.SRC(&IN3MEM),OUTMEM=&OUT3,HLQ=&HLQ
// ELSE
//CC3    EXEC PGM=IEFBR14
// ENDIF
// IF (&USE4 EQ 1) THEN
//CC4    EXEC CCOMP,INFILE=&HLQ..LUA.SRC(&IN4MEM),OUTMEM=&OUT4,HLQ=&HLQ
// ELSE
//CC4    EXEC PGM=IEFBR14
// ENDIF
//LKED   EXEC PGM=HEWL,PARM='LIST,MAP,XREF,LET',REGION=0M
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSLMOD  DD DSN=&HLQ..LUA.LOAD(&LMEM),DISP=SHR
//SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR
//OBJLIB   DD DSN=&HLQ..LUA.OBJ,DISP=SHR
//SYSLIN   DD DUMMY
//         PEND
