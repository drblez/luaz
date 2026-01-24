//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Validate LUAIN inline FB80 input via LUACMD -> LUAEXEC.
//* Objects:
//* +---------+----------------------------------------------+
//* | RUN     | Execute inline LUAIN Lua script via LUACMD    |
//* +---------+----------------------------------------------+
//* DDNAMEs:
//* - STEPLIB: &HLQ..LUA.LOADLIB (LUAEXEC/LUACMD)
//* - LUAIN: In-stream (FB80) Lua script
//* - SYSTSPRT/SYSOUT/SYSPRINT/SYSUDUMP: SYSOUT
//* Expected RC:
//* - RUN: 0
//ITLFB80 JOB (ACCT),'IT LUAINFB',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
//* Run integration test script from inline FB80 LUAIN
//RUN     EXEC PGM=IKJEFT01
//STEPLIB  DD DSN=&HLQ..LUA.LOADLIB,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  LUACMD ARG1 'ARG TWO' ARG3=Z ARG4
/*
//SYSEXEC DD DSN=&HLQ..LUA.REXX,DISP=SHR
//LUAIN   DD *
local function fail(tag)
  print("LUZ30091 ITLUAINFB fail "..tag)
  return 8
end
if LUAZ_MODE ~= "TSO" then
  return fail("mode")
end
if arg[0] ~= "DD:LUAIN" then
  return fail("arg0")
end
if arg[1] ~= "ARG1" then
  return fail("arg1")
end
if arg[2] ~= "ARG TWO" then
  return fail("arg2")
end
if arg[3] ~= "ARG3=Z" then
  return fail("arg3")
end
if arg[4] ~= "ARG4" then
  return fail("arg4")
end
if arg[5] ~= nil then
  return fail("arg5")
end
print("LUZ30090 ITLUAINFB ok LUAZ_MODE=TSO args ok")
return 0
/*
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*
