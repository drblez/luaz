//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Sample IKJEFT01 job for Lua/TSO batch execution
//*
//* Object Table:
//* | Step | Purpose |
//* |------|---------|
//* | LUABATCH | Run TSO Terminal Monitor Program with SYSTSIN |
//*
//LUABATCH EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  /* Example: CALL 'HLQ.LUA.LOAD(LUAEXEC)' */
/*
