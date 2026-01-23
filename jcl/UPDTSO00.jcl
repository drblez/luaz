//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Update IKJTSO00 with LUAEXEC/LUACMD in AUTH lists.
//* Notes: Requires authority to update SYS1.PARMLIB.
//UPTSO00 JOB (ACCT),'UPD IKJTSO00',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//STEP1   EXEC PGM=IEBUPDTE,PARM=NEW
//SYSPRINT DD SYSOUT=*
//SYSUT2   DD DSN=SYS1.PARMLIB,DISP=SHR
//SYSIN    DD *
./ ADD NAME=IKJTSO00,LIST=ALL
AUTHCMD NAMES(               +
   ACCOUNT                   +
   EYU9XENF                  +
   RECEIVE                   +
   TRANSMIT XMIT             +
   LISTB    LISTBC           +
   SE       SEND             +
   RACONVRT                  +
   SYNC                      +
   PARMLIB  IKJPRMLB         +
   CONSOLE                   +
   TSOAUTH                   +
   OUTPUT2                   +
   CONSPROF                  +
   WSMMWF00                  +
                             +
   MVPXDISP                  +
   NETSTAT                   +
   TRACERTE                  +
   PING                      +
                             +
   AD       ADDSD            +
   AG       ADDGROUP         +
   AU       ADDUSER          +
   ALG      ALTGROUP         +
   ALD      ALTDSD           +
   ALU      ALTUSER          +
   BLKUPD                    +
   CO       CONNECT          +
   DD       DELDSD           +
   DG       DELGROUP         +
   DU       DELUSER          +
   LD       LISTDSD          +
   LG       LISTGRP          +
   LU       LISTUSER         +
   RACDCERT RACDCERT         +
   RALT     RALTER           +
   RDEF     RDEFINE          +
   RDEL     RDELETE          +
   RE       REMOVE           +
   RL       RLIST            +
   RVARY                     +
   PW       PASSWORD         +
   PE       PERMIT           +
   SETR     SETROPTS         +
   SR       SEARCH           +
   TESTA                     +
   TESTAUTH                  +
   ICHEINTY                  +
   IRRDPI00                  +
   FRACHECK                  +
   RACDEF                    +
   RACHECK                   +
   RACINIT                   +
   CALLRACF                  +
   CALLLIST                  +
   RACLIST                   +
   RACXTRT                   +
   DEFINE                    +
   DELETE                    +
   DENQ                      +
   DITTO                     +
   Q                         +
   QCBXA                     +
   QCBTRACE                  +
   EISA                      +
   EISA370                   +
   EISAXA                    +
   IOCDS                     +
   LISTD                     +
   LISTDS                    +
   LIBLIST                   +
   VLFNOTE                   +
   CSTLCO01                  +
   CSTLCOA2                  +
   CSTLCOA3                  +
   A1CMD1                    +
   A1CMD2                    +
   A1CMD3                    +
   A1CMD4                    +
   CONCATPA                  +
   PERMALOC PA               +
   TUC RACLINK               +
   SPECIAL                   +
   LUACMD                   +
   SHCDS)

AUTHPGM NAMES(               +
   IEBCOPY                   +
   IDCAMS                    +
   IFASMFDP                  +
   ADRDSSU                   +
                             +
   ICHUT100                  +
   ICHUT200                  +
   ICHUT400                  +
   ICHUEX00                  +
   ICHEINTY                  +
                             +
   ICHUT00                   +
   VSMDI901                  +
   VSMDI902                  +
   VSMFG900                  +
   VSMFG903                  +
   VSMMN916                  +
   VSMZZ904                  +
   IRRDPI00                  +
   DENQ                      +
   QCBXA                     +
   EISA                      +
   EISA370                   +
   EISAXA                    +
   LIBLIST                   +
   IKJEFF76                  +
   ISSUECMD                  +
   WSMMWF00                  +
   CSFDAUTH                  +
   CSTLCO01                  +
   CSTLCOA2                  +
   TSNENV TSNOUT LUAEXEC                   +
   TSOAUTH                   +
   CSTLCOA3)

NOTBKGND NAMES(              +
   OPER     OPERATOR         +
   TERM     TERMINAL)

AUTHTSF NAMES(               +
   IEBCOPY                   +
   IKJEFF76                  +
   EQQMINOR                  +
   ISSUECMD                  +
   CHNGSKEY                  +
   WSMMWF00                  +
   WLMMON00                  +
   WLMTSMON                  +
   IWMA2PMI                  +
   IHVUUSD                   +
   CSFDAUTH                  +
   CSTLCO01                  +
   CSTLCOA2                  +
   TSOAUTH                   +
   LUAEXEC                   +
   CSTLCOA3)


SEND                         +
   OPERSEND(ON)              +
   USERSEND(ON)              +
   SAVE(ON)                  +
   CHKBROD(ON)               +
   USEBROD(ON)               +
   MSGPROTECT(OFF)           +
   BROADCAST(DATASET(SYS1.VS01.BRODCAST))  +
   LOGNAME(*)

TRANSREC NODESMF((*,*))      +
         CIPHER(YES)         +
         SPOOLCL(B)          +
         OUTWARN(10000,5000) +
         OUTLIM(100000)      +
         VIO(SYSDA)          +
         LOGSEL(LOG)         +
         LOGNAME(MISC)       +
         DAPREFIX(TUPREFIX)  +
         USRCTL(NAMES.TEXT)  +
         SYSOUT(*)

LOGON                        +
   PASSPHRASE(ON)            +
   PASSWORDPREPROMPT(ON)
./ ENDUP
/*
