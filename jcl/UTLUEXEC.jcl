//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Direct CALL LUAEXEC test under IKJEFT01.
//* Objects:
//* +---------+----------------------------------------------+
//* | RUN     | CALL LUAEXEC MODE=TSO (no LUACMD)            |
//* +---------+----------------------------------------------+
//UTLUEXEC JOB (ACCT),'UT LUAEXEC',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
//RUN     EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  CALL 'DRBLEZ.LUA.LOADLIB(LUAEXEC)' 'MODE=TSO'
/*
//SYSEXEC DD DSN=&HLQ..LUA.REXX,DISP=SHR
//LUAIN   DD DSN=&HLQ..LUA.TEST(ITTSO),DISP=SHR
//TSOOUT  DD DSN=&&TSOOUT,DISP=(NEW,PASS),
//            UNIT=SYSDA,SPACE=(TRK,(5,5)),
//            RECFM=VB,LRECL=1024,BLKSIZE=0
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
