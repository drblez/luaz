//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Unit test LUAPATH + LUAMAP resolution in batch.
//* Objects:
//* +---------+--------------------------------------------+
//* | ALLOC   | Allocate temp LUAPATH PDS                  |
//* | MAPGEN  | Create LUAMAP member                       |
//* | SHORT   | Create SHORT member                         |
//* | LONG    | Create VLONG01 member                      |
//* | UTBLD   | Compile LUAPUT deps and link into &HLQ..LUA.LOAD |
//* | RUN     | Execute LUAPUT with LUAPATH DD             |
//* +---------+--------------------------------------------+
//UTLUPATH JOB (ACCT),'UT LUAPATH',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
//JCLLIB  ORDER=&HLQ..LUA.JCL
//*
//ALLOC   EXEC PGM=IEFBR14
//LUAPATH DD DSN=&&LUAPTH,DISP=(NEW,PASS),
//            DSORG=PO,RECFM=FB,LRECL=80,BLKSIZE=0,
//            SPACE=(CYL,(1,1,5)),UNIT=SYSDA,DSNTYPE=LIBRARY
//*
//MAPGEN  EXEC PGM=IEBGENER
//SYSUT1  DD *
# LUAMAP for UT_LUAPATH
very.long.name = VLONG01
/*
//SYSUT2  DD DSN=&&LUAPTH(LUAMAP),DISP=(OLD,KEEP)
//SYSPRINT DD SYSOUT=*
//SYSIN   DD DUMMY
//*
//SHORT   EXEC PGM=IEBGENER
//SYSUT1  DD *
return 1
/*
//SYSUT2  DD DSN=&&LUAPTH(SHORT),DISP=(OLD,KEEP)
//SYSPRINT DD SYSOUT=*
//SYSIN   DD DUMMY
//*
//LONG    EXEC PGM=IEBGENER
//SYSUT1  DD *
return { ok = true }
/*
//SYSUT2  DD DSN=&&LUAPTH(VLONG01),DISP=(OLD,KEEP)
//SYSPRINT DD SYSOUT=*
//SYSIN   DD DUMMY
//*
//UTBLD  EXEC UTBLD,HLQ=&HLQ,
//         IN1=&HLQ..LUA.SRC(LUAPUT),OUT1=LUAPUT,
//         IN2=&HLQ..LUA.SRC(IODD),OUT2=IODD,
//         IN3=&HLQ..LUA.SRC(PLATFORM),OUT3=PLATFORM,
//         IN4=&HLQ..LUA.SRC(PATH),OUT4=PATH,
//         LMEM=LUAPUT
//UTBLD.LKED.SYSLIN DD *
  INCLUDE OBJLIB(LUAPUT)
  INCLUDE OBJLIB(IODD)
  INCLUDE OBJLIB(PLATFORM)
  INCLUDE OBJLIB(PATH)
  NAME LUAPUT(R)
/*
//*
//RUN     EXEC PGM=LUAPUT,COND=(0,NE,UTBLD)
//STEPLIB DD DSN=&HLQ..LUA.LOAD,DISP=SHR
//LUAPATH DD DSN=&&LUAPTH,DISP=(OLD,DELETE)
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
