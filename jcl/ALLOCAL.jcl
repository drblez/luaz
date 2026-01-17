//ALLOCALL JOB (ACCT),'ALLOC PDSE',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID
//         SET HLQ=DRBLEZ
//* Allocate PDSE structure for Lua/TSO build
//ALLOC    EXEC PGM=IEFBR14
//* C/C++ sources
//SRC      DD  DSN=&HLQ..LUA.SRC,
//             DISP=(NEW,CATLG,DELETE),DSORG=PO,DSNTYPE=LIBRARY,
//             UNIT=SYSDA,SPACE=(CYL,(30,10)),
//             RECFM=VB,LRECL=255,BLKSIZE=0
//* Headers
//INC      DD  DSN=&HLQ..LUA.INC,
//             DISP=(NEW,CATLG,DELETE),DSORG=PO,DSNTYPE=LIBRARY,
//             UNIT=SYSDA,SPACE=(CYL,(10,5)),
//             RECFM=VB,LRECL=255,BLKSIZE=0
//* Lua modules
//LUA      DD  DSN=&HLQ..LUA.LUA,
//             DISP=(NEW,CATLG,DELETE),DSORG=PO,DSNTYPE=LIBRARY,
//             UNIT=SYSDA,SPACE=(CYL,(5,5)),
//             RECFM=FB,LRECL=80,BLKSIZE=0
//* JCL library
//JCL      DD  DSN=&HLQ..LUA.JCL,
//             DISP=(NEW,CATLG,DELETE),DSORG=PO,DSNTYPE=LIBRARY,
//             UNIT=SYSDA,SPACE=(CYL,(5,5)),
//             RECFM=FB,LRECL=80,BLKSIZE=0
//* Objects
//OBJ      DD  DSN=&HLQ..LUA.OBJ,
//             DISP=(NEW,CATLG,DELETE),DSORG=PO,DSNTYPE=LIBRARY,
//             UNIT=SYSDA,SPACE=(CYL,(20,10)),
//             RECFM=U,LRECL=0,BLKSIZE=32760
//* Load module
//LOAD     DD  DSN=&HLQ..LUA.LOAD,
//             DISP=(NEW,CATLG,DELETE),DSORG=PO,DSNTYPE=LIBRARY,
//             UNIT=SYSDA,SPACE=(CYL,(10,5)),
//             RECFM=U,LRECL=0,BLKSIZE=32760
//* Tests (optional)
//TEST     DD  DSN=&HLQ..LUA.TEST,
//             DISP=(NEW,CATLG,DELETE),DSORG=PO,DSNTYPE=LIBRARY,
//             UNIT=SYSDA,SPACE=(CYL,(5,5)),
//             RECFM=FB,LRECL=80,BLKSIZE=0
