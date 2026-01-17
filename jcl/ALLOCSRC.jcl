//ALLOC    JOB (ACCT),'ALLOC SRC',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID
//* Allocate PDSE for Lua/TSO sources and docs
//ALLOC    EXEC PGM=IEFBR14
//SRC      DD  DSN=DRBLEZ.LUA.SRC,
//             DISP=(NEW,CATLG,DELETE),
//             DSORG=PO,
//             DSNTYPE=LIBRARY,
//             UNIT=SYSDA,
//             SPACE=(CYL,(30,10)),
//             RECFM=FB,
//             LRECL=80,
//             BLKSIZE=0
