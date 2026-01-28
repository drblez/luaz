//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Integration test for LUACFG behavior via LUACMD.
//* Objects:
//* +---------+----------------------------------------------+
//* | RUN     | Execute ITLUACFG Lua script via LUACMD        |
//* +---------+----------------------------------------------+
//ITLUACFG JOB (ACCT),'IT LUACFG',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
//* Run integration test script
//RUN     EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//CFGIN   DD DSN=&HLQ..LUA.TEST(ITLUACFG),DISP=SHR
//LUACFG  DD *
  allow.tso.cmd = whitelist
  tso.cmd.whitelist = LISTCAT
  tso.cmd.capture.default = false
  limits.output.lines = 10
  luain.dd = CFGIN
  luaout.dd = CFGOUT
  luapath.dd = LUAPATH
/*
//CFGOUT  DD SYSOUT=*
//SYSTSIN  DD *
  TSOLIB ACTIVATE DSNAME('DRBLEZ.LUA.LOADLIB')
  TSOLIB DISPLAY
  LUACMD
/*
//*
