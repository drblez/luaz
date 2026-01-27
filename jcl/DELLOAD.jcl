//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Remove LUACMD/LUAEXEC from DRBLEZ.LUA.LOAD to avoid APF conflicts.
//* DDNAME inputs: SYSIN (IDCAMS control).
//* DDNAME outputs: SYSPRINT (reports).
//* Expected RC: 0 when members are deleted, 8 if a member is missing.
//DELLOAD JOB (ACCT),'DEL LOAD MODS',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//DEL     EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'DRBLEZ.LUA.LOAD(LUACMD)'
  DELETE 'DRBLEZ.LUA.LOAD(LUAEXEC)'
/*
