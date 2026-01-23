//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Recreate DRBLEZ.LUA.TEST with VB/1024 for Lua tests.
//* Objects:
//* +---------+----------------------------------------------+
//* | DELTST  | Delete DRBLEZ.LUA.TEST                       |
//* | ALCTST  | Allocate DRBLEZ.LUA.TEST (VB, LRECL=1024)    |
//* +---------+----------------------------------------------+
//ALLOCTST JOB (ACCT),'ALLOC TEST',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID
//DELTST  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE 'DRBLEZ.LUA.TEST' PURGE
  SET MAXCC=0
/*
//ALCTST  EXEC PGM=IEFBR14,COND=EVEN
//TEST    DD  DSN=DRBLEZ.LUA.TEST,
//             DISP=(NEW,CATLG,DELETE),DSORG=PO,DSNTYPE=LIBRARY,
//             UNIT=SYSDA,SPACE=(CYL,(5,5)),
//             RECFM=VB,LRECL=1024,BLKSIZE=0
//*
