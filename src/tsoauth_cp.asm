* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
*
* TSOAUTH -- TSO command processor (TMP-required).
*
* Object Table:
* | Object  | Kind  | Purpose |
* |---------|-------|---------|
* | TSOAUTH | CSECT | Execute TSO command from input line |
*
* User Actions:
* - Link with AC=1 into APF-authorized library DRBLEZ.LUA.LOAD.
* - Ensure TSOAUTH is listed in AUTHPGM/AUTHTSF.
* - Ensure TSOAUTH is listed in AUTHCMD in IKJTSO00.
* - Activate IKJTSO00 changes before running.
* - Run under IKJEFT01 (TMP) for SYSTSPRT output.
*
* Command usage from SYSTSIN:
*   TSOAUTH <TSO-command>
*
TSOAUTH  CSECT                                  Entry point CSECT.
TSOAUTH  AMODE 31                                Use 31-bit addressing.
TSOAUTH  RMODE ANY                               Allow load any region.
R0       EQU   0                                 Register 0 alias.
R1       EQU   1                                 Register 1 alias.
R2       EQU   2                                 Register 2 alias.
R3       EQU   3                                 Register 3 alias.
R4       EQU   4                                 Register 4 alias.
R5       EQU   5                                 Register 5 alias.
R6       EQU   6                                 Register 6 alias.
R7       EQU   7                                 Register 7 alias.
R8       EQU   8                                 Register 8 alias.
R9       EQU   9                                 Register 9 alias.
R10      EQU   10                                Register 10 alias.
R11      EQU   11                                Register 11 alias.
R12      EQU   12                                Register 12 alias.
R13      EQU   13                                Register 13 alias.
R14      EQU   14                                Register 14 alias.
R15      EQU   15                                Register 15 alias.
         STM   R14,R12,12(R13)                   Save caller regs.
* Establish base register at CSECT start.
         LARL  R12,TSOAUTH                       Load CSECT base.
         USING TSOAUTH,R12                       Base addr on CSECT.
         LA    R15,SAVE                          Point to save area.
         ST    R13,4(R15)                        Chain back save area.
         ST    R15,8(R13)                        Chain forward save.
         LR    R13,R15                           Activate save area.
         LR    R10,R1                            Save CPPL address.
         USING CPPL,R10                          Map CPPL fields.
         LA    R9,WORKAREA                       Set work area ptr.
         USING WORKAREA,R9                       Map work fields.
         L     R2,CPPLCBUF                       Load cmd buffer ptr.
         LTR   R2,R2                             Test buffer ptr.
         BZ    NO_CMD                            Fail: no buffer.
         LH    R3,0(R2)                          Load buffer length.
         CHI   R3,4                              Validate min length.
         BL    NO_CMD                            Fail: no text.
         AHI   R3,-4                             Subtract header.
         LA    R4,4(R2)                          Point to text.
SKIPSP1  LTR   R3,R3                             Check remaining.
         BZ    NO_CMD                            Fail: empty.
         CLI   0(R4),X'40'                       Skip leading space.
         BNE   TOKSTART                          Start token scan.
         LA    R4,1(R4)                          Advance text ptr.
         BCT   R3,SKIPSP1                        Dec len and loop.
TOKSTART LTR   R3,R3                             Check remaining.
         BZ    NO_CMD                            Fail: no token.
TOKLOOP  CLI   0(R4),X'40'                       Check token end.
         BE    SKIPSP2                           Jump to operands.
         LA    R4,1(R4)                          Advance in token.
         BCT   R3,TOKLOOP                        Dec len and loop.
         B     NO_CMD                            Fail: no operands.
SKIPSP2  LTR   R3,R3                             Check remaining.
         BZ    NO_CMD                            Fail: no operands.
         CLI   0(R4),X'40'                       Skip token space.
         BNE   CMDREADY                          Operand starts.
         LA    R4,1(R4)                          Advance operand ptr.
         BCT   R3,SKIPSP2                        Dec len and loop.
CMDREADY ST    R3,CMDLEN                         Store cmd length.
         ST    R3,REMLEN                         Store rem length.
         XC    FLAGS,FLAGS                       Clear flags.
* Use authorized environment flags for IKJEFTSR.
         MVI   FLAGS+1,X'00'
         MVI   FLAGS+3,X'01'                     Set command flag.
         XC    RCCODE,RCCODE                     Clear rc.
         XC    RSNCODE,RSNCODE                   Clear reason.
         XC    ABEND,ABEND                       Clear abend.
         LA    R7,FLAGS                          Addr: flags.
         ST    R7,PLIST+0                        Parm1: flags.
         ST    R4,PLIST+4                        Parm2: cmd ptr.
         LA    R7,CMDLEN                         Addr: cmd len.
         ST    R7,PLIST+8                        Parm3: cmd len.
         LA    R7,RCCODE                         Addr: rc.
         ST    R7,PLIST+12                       Parm4: rc.
         LA    R7,RSNCODE                        Addr: reason.
         ST    R7,PLIST+16                       Parm5: reason.
         LA    R7,ABEND                          Addr: abend.
         O     R7,=X'80000000'                   Mark last parm.
         ST    R7,PLIST+20                       Parm6: abend.
         LA    R1,PLIST                          R1 -> plist.
         L     R15,CVTPTR                        Load CVT.
         L     R15,CVTTVT(,R15)                  Load TVT.
         L     R15,TSVTASF-TSVT(,R15)            Load TSF entry.
         BALR  R14,R15                           Call IKJEFTSR.
* Format rc/rsn/abend into output line.
         L     R7,RCCODE                         Load rc value.
         CVD   R7,PACKRC                         Convert rc to packed.
         MVC   EDMASKW,EDMASK0                   Copy edit mask.
         ED    EDMASKW,PACKRC                    Edit rc value.
         MVC   OUTTXT+RC_POS(8),EDMASKW          Store rc text.
         L     R7,RSNCODE                         Load reason value.
         CVD   R7,PACKRSN                         Convert reason.
         MVC   EDMASKW,EDMASK0                    Copy edit mask.
         ED    EDMASKW,PACKRSN                    Edit reason.
         MVC   OUTTXT+RSN_POS(8),EDMASKW         Store reason text.
         L     R7,ABEND                           Load abend value.
         CVD   R7,PACKABD                         Convert abend.
         MVC   EDMASKW,EDMASK0                    Copy edit mask.
         ED    EDMASKW,PACKABD                    Edit abend.
         MVC   OUTTXT+ABD_POS(8),EDMASKW         Store abend text.
* Write line to SYSTSPRT via PUTLINE.
         L     R3,CPPLUPT                        Load UPT ptr.
         L     R4,CPPLECT                        Load ECT ptr.
* PUTLINE execute form with continuation indicator.
         PUTLINE PARM=PUTPARM,UPT=(R3),ECT=(R4),ECB=ECBADS,  X
               OUTPUT=(OUTLINE,TERM,SINGLE,DATA),MF=(E,IOPLADS)
         L     R15,RCCODE                        Return rc.
         B     EPILOG                            Exit.
NO_CMD   L     R15,=F'12'                        RC=12 invalid.
EPILOG   L     R13,4(R13)                        Restore save area.
         LM    R14,R12,12(R13)                   Restore regs.
         BR    R14                               Return.
SAVE     DS    18F                               Local save area.
WORKAREA DS    0F                                Work area anchor.
FLAGS    DS    XL4                               IKJEFTSR flags.
CMDLEN   DS    F                                 Command length.
REMLEN   DS    F                                 Remaining length.
RCCODE   DS    F                                 Return code.
RSNCODE  DS    F                                 Reason code.
ABEND    DS    F                                 Abend code.
PLIST    DS    6F                                IKJEFTSR plist.
* PUTLINE working storage.
ECBADS   DS    F                                 PUTLINE ECB.
IOPLADS  DS    4F                                PUTLINE IOPL.
PUTPARM  PUTLINE MF=L                            PUTLINE parm.
EDMASK0  DC    X'F0F0F0F0F0F0F0F0'               Edit mask.
EDMASKW  DS    CL8                               Edit work.
PACKRC   DS    D                                 Packed rc.
PACKRSN  DS    D                                 Packed reason.
PACKABD  DS    D                                 Packed abend.
OUTLINE  DC    H'52',H'0'                        Line hdr.
OUTTXT   DC    CL40'LUZ10010 RC=00000000 RSN=00000000 ABEND=' Text p1.
         DC    CL8'00000000'                                Text p2.
RC_POS   EQU   12                                RC offset.
RSN_POS  EQU   25                                RSN offset.
ABD_POS  EQU   40                                Abend offset.
CPPL     DSECT                                   CPPL DSECT anchor.
         IKJCPPL                                 CPPL layout mapping.
CVTPTR   EQU   16                                PSA->CVT pointer.
CVTTVT   EQU   X'9C'                             CVT->TVT offset.
         IKJTSVT                                 TSVT layout mapping.
         END   TSOAUTH                           End of module.
