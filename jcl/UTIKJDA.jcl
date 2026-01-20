//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Dump DAIR-related macros from SYS1.MACLIB.
//* Objects:
//* +---------+----------------------------------------------+
//* | DAPL    | Print IKJDAPL macro source                   |
//* | DAP00   | Print IKJDAP00 macro source                  |
//* | DAP04   | Print IKJDAP04 macro source                  |
//* | DAP08   | Print IKJDAP08 macro source                  |
//* | DAP10   | Print IKJDAP10 macro source                  |
//* | DAP14   | Print IKJDAP14 macro source                  |
//* | DAP18   | Print IKJDAP18 macro source                  |
//* | DFAIL   | Print IKJEFFDF macro source                  |
//* +---------+----------------------------------------------+
//UTIKJDA JOB (ACCT),'UT IKJDAIR',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//DAPL   EXEC PGM=IEBGENER
//SYSUT1   DD DSN=SYS1.MACLIB(IKJDAPL),DISP=SHR
//SYSUT2   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//* 
//DAP00  EXEC PGM=IEBGENER
//SYSUT1   DD DSN=SYS1.MACLIB(IKJDAP00),DISP=SHR
//SYSUT2   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//* 
//DAP04  EXEC PGM=IEBGENER
//SYSUT1   DD DSN=SYS1.MACLIB(IKJDAP04),DISP=SHR
//SYSUT2   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//* 
//DAP08  EXEC PGM=IEBGENER
//SYSUT1   DD DSN=SYS1.MACLIB(IKJDAP08),DISP=SHR
//SYSUT2   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//* 
//DAP10  EXEC PGM=IEBGENER
//SYSUT1   DD DSN=SYS1.MACLIB(IKJDAP10),DISP=SHR
//SYSUT2   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//* 
//DAP14  EXEC PGM=IEBGENER
//SYSUT1   DD DSN=SYS1.MACLIB(IKJDAP14),DISP=SHR
//SYSUT2   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//* 
//DAP18  EXEC PGM=IEBGENER
//SYSUT1   DD DSN=SYS1.MACLIB(IKJDAP18),DISP=SHR
//SYSUT2   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//* 
//DFAIL   EXEC PGM=IEBGENER
//SYSUT1   DD DSN=SYS1.MACLIB(IKJEFFDF),DISP=SHR
//SYSUT2   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
