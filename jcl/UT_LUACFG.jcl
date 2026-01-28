//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Unit test LUACFG parsing via luaz_policy_load.
//* Objects:
//* +---------+-----------------------------------------------+
//* | UTBLD   | Compile LUACFGUT and POLICY                   |
//* | RUN     | Execute LUACFGUT with LUACFG DD               |
//* +---------+-----------------------------------------------+
//UTLUACFG JOB (ACCT),'UT LUACFG',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
// JCLLIB ORDER=&HLQ..LUA.JCL
//*
//UTBLD  EXEC UTBLD,HLQ=&HLQ,
//         IN1MEM=LUACFGUT,OUT1=LUACFGUT,
//         USE2=1,IN2MEM=POLICY,OUT2=POLICY,
//         LMEM=LUACFGUT
//LKED.SYSLIN DD *
  INCLUDE OBJLIB(LUACFGUT)
  INCLUDE OBJLIB(POLICY)
  NAME LUACFGUT(R)
/*
//*
//RUN     EXEC PGM=LUACFGUT,COND=(0,NE,UTBLD.LKED)
//STEPLIB DD DSN=&HLQ..LUA.LOAD,DISP=SHR
//LUACFG  DD *
# LUACFG for UT_LUACFG
allow.tso.cmd = whitelist

tso.cmd.whitelist = LISTCAT

# Comments and blank lines should be ignored
*tso.cmd.blacklist = TIME

limits.output.lines = 25

tso.cmd.capture.default = true

tso.rexx.dd = SYSEXEC

tso.rexx.exec = LUTSO

luain.dd = LUAIN
luaout.dd = LUAOUT
luapath.dd = LUAPATH
/*
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
