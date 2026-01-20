//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Allocate ASM PDSE for assembler sources.
//* Objects:
//* +---------+----------------------------------------------+
//* | ALLOC   | Create DRBLEZ.LUA.ASM as FB/80 PDSE           |
//* +---------+----------------------------------------------+
//ALLOCASM JOB (ACCT),'ALLOC ASM',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
//ALLOC   EXEC PGM=IEFBR14
//ASM     DD  DSN=&HLQ..LUA.ASM,DISP=(NEW,CATLG,DELETE),
//            DSORG=PO,DSNTYPE=LIBRARY,
//            RECFM=FB,LRECL=80,BLKSIZE=0,
//            SPACE=(CYL,(1,1,1)),UNIT=SYSDA
//*
