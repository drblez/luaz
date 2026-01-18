//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Allocate PDSE for source hash members.
//* Objects:
//* +---------+----------------------------------------------+
//* | ALLOC   | Create &HLQ..LUA.SRC.HASHES PDSE             |
//* +---------+----------------------------------------------+
//ALLOCHSH JOB (ACCT),'ALLOC HASH',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID
//         SET HLQ=DRBLEZ
//ALLOC   EXEC PGM=IEFBR14
//HASHES  DD  DSN=&HLQ..LUA.SRC.HASHES,
//             DISP=(NEW,CATLG,DELETE),
//             DSORG=PO,DSNTYPE=LIBRARY,
//             RECFM=FB,LRECL=80,BLKSIZE=0,
//             SPACE=(TRK,(1,1,1)),UNIT=SYSALLDA
//
