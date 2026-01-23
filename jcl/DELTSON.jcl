//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Delete OBJ member TSONATV to force rebuild.
//* Objects:
//* +---------+----------------------------------------------+
//* | DEL     | Delete DRBLEZ.LUA.OBJ(TSONATV)               |
//* | DELHASH | Delete DRBLEZ.LUA.SRC.HASHES(TSONATV)        |
//* +---------+----------------------------------------------+
//DELTSON JOB (ACCT),'DEL TSONATV',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID
//DEL     EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE DRBLEZ.LUA.OBJ(TSONATV) PURGE
  DELETE DRBLEZ.LUA.SRC.HASHES(TSONATV) PURGE
  SET MAXCC=0
/*
