//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Remove LUACMD from DRBLEZ.LUA.LOADLIB for isolation test.
//* DDNAME inputs: SYSIN (IDCAMS control).
//* DDNAME outputs: SYSPRINT (reports).
//* Expected RC: 0 when member is deleted, 8 if missing.
//DELLODLB JOB (ACCT),'DEL LOADLIB',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//DEL     EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'DRBLEZ.LUA.LOADLIB(LUACMD)'
/*
