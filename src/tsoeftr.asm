* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
*
* Authorized IKJEFTSR wrapper (requires TMP/IKJEFT01).
*
* Object Table:
* | Object | Kind | Purpose |
* | TSOEFTR | CSECT | Call IKJEFTSR under TMP |
*
* User Actions:
* - Link with AC=1 into APF-authorized library.
* - Add TSOEFTR to AUTHPGM/AUTHTSF in IKJTSO00.
* - Activate IKJTSO00 changes before running.
* - Run under IKJEFT01 (TMP) so TSO command output is routed.
*
* Emit assembler listing for debugging.
         PRINT GEN                              Listing on.
* Define entry point control section.
TSOEFTR  CEEENTRY PPA=TSOPPA,MAIN=NO,PLIST=OS,PARMREG=1  LE entry.
* Use default AMODE/RMODE from CEEENTRY.
* Register name aliases.
R0       EQU   0                                Register 0 alias.
* Register name aliases.
R1       EQU   1                                Register 1 alias.
* Register name aliases.
R2       EQU   2                                Register 2 alias.
* Register name aliases.
R3       EQU   3                                Register 3 alias.
* Register name aliases.
R4       EQU   4                                Register 4 alias.
* Register name aliases.
R5       EQU   5                                Register 5 alias.
* Register name aliases.
R6       EQU   6                                Register 6 alias.
* Register name aliases.
R7       EQU   7                                Register 7 alias.
* Register name aliases.
R8       EQU   8                                Register 8 alias.
* Register name aliases.
R9       EQU   9                                Register 9 alias.
* Register name aliases.
R10      EQU   10                               Register 10 alias.
* Register name aliases.
R11      EQU   11                               Register 11 alias.
* Register name aliases.
R12      EQU   12                               Register 12 alias.
* Register name aliases.
R13      EQU   13                               Register 13 alias.
* Register name aliases.
R14      EQU   14                               Register 14 alias.
* Register name aliases.
R15      EQU   15                               Register 15 alias.
* External entry points.
         EXTRN IKJEFTSR                          External IKJEFTSR.
* Set base register to this CSECT.
         LARL  R11,TSOEFTR                        Load base register.
* CAA addressability for LE services.
         USING CEECAA,R12                         CAA addressability.
* DSA addressability for LE services.
         USING CEEDSA,R13                         DSA addressability.
* CSECT base addressability.
         USING TSOEFTR,R11                        Base addressability.
* Preserve caller parameter list pointer.
         LR    R8,R1                              Save plist ptr.
* Load command pointer address from parm list.
         L     R2,0(R8)                           Load cmd slot.
* Load command pointer from caller slot.
         L     R2,0(R2)                           Load cmd pointer.
* Load command length pointer address from list.
         L     R3,4(R8)                           Load len slot.
* Load command length pointer from caller slot.
         L     R3,0(R3)                           Load len pointer.
* Load rc pointer address from parm list.
         L     R4,8(R8)                           Load rc slot.
* Load rc pointer from caller slot.
         L     R4,0(R4)                           Load rc pointer.
* Load reason pointer address from parm list.
         L     R5,12(R8)                          Load reason slot.
* Load reason pointer from caller slot.
         L     R5,0(R5)                           Load reason pointer.
* Load work area pointer address from parm list.
         L     R6,16(R8)                          Load work slot.
* Clear end-of-plist high bit on last slot.
         N     R6,=X'7FFFFFFF'                    Clear HOB.
* Load work area pointer from caller slot.
         L     R6,0(R6)                           Load work pointer.
* Validate work area pointer from caller.
         LTR   R6,R6                              Check for NULL.
         BZ    FAIL_NOHEAP                        Fail if no work area.
* Save work area address in base register.
         LR    R9,R6                              Use caller work area.
* Establish work area base register.
         USING WORKAREA,R9                       Use work area base.
* Clear work area for clean defaults.
         XC    0(WORKSIZE,R9),0(R9)              Clear work area.
* Save length pointer for later use.
         ST    R3,CMDLENP(R9)                    Store length pointer.
* Save rc pointer for later use.
         ST    R4,RCPTR(R9)                      Store rc pointer.
* Save reason pointer for later use.
         ST    R5,REASONP(R9)                    Store reason pointer.
* Proceed to IKJEFTSR parameter setup (TMP already active).
* Reload cmd pointer for IKJEFTSR.
         L     R2,CMDPTR(R9)                     Reload cmd ptr.
* Reload length pointer for IKJEFTSR.
         L     R3,CMDLENP(R9)                    Reload length pointer.
* Reload rc pointer for IKJEFTSR.
         L     R4,RCPTR(R9)                      Reload rc pointer.
* Reload reason pointer for IKJEFTSR.
         L     R5,REASONP(R9)                    Reload reason pointer.
* Point to IKJEFTSR parameter list.
         LA    R6,SR_PLIST(R9)                   Point to SR plist.
* Prepare IKJEFTSR flags address.
         LA    R7,SR_FLAGS(R9)                   Point to flags.
* Store parm1 (flags address).
         ST    R7,0(R6)                          Store flags pointer.
* Store parm2 (cmd pointer).
         ST    R2,4(R6)                          Store command pointer.
* Store parm3 (cmd length pointer).
         ST    R3,8(R6)                          Store length pointer.
* Store parm4 (rc pointer).
         ST    R4,12(R6)                         Store rc pointer.
* Store parm5 (reason pointer).
         ST    R5,16(R6)                         Store reason pointer.
* Prepare IKJEFTSR abend code.
         LA    R7,SR_ABEND(R9)                   Point to abend code.
* Mark last parm in list per LE.
         O     R7,=X'80000000'                   Mark last parameter.
* Store parm6 (abend code).
         ST    R7,20(R6)                         Store abend pointer.
* Initialize IKJEFTSR flags (command, isolated).
         LA    R7,SR_FLAGS(R9)                   Point to flags.
         MVI   0(R7),X'00'                        Reserved flags.
         MVI   1(R7),X'00'                        Isolated environment.
         MVI   2(R7),X'00'                        No dump on abend.
         MVI   3(R7),X'01'                        Command indicator.
* Point R1 to IKJEFTSR parameter list.
         LA    R1,SR_PLIST(R9)                    R1 -> IKJEFTSR plist.
* Locate TSO service facility entry point.
         L     R15,CVTPTR                         Load CVT address.
         L     R15,CVTTVT(,R15)                   Load TVT address.
         L     R15,TSVTASF-TSVT(,R15)             Load TSVTASF entry.
* Execute the TSO command via TSO service facility.
         BALR  R14,R15                            Branch to TSF entry.
* Continue to cleanup path.
         B     DONE                              Branch to cleanup.
* Alias for any failure after workarea is set.
FAIL     B     FAIL_NOHEAP                       Fail branch.
* Check rc pointer before storing error.
FAIL_NOHEAP LTR   R4,R4                          Test rc pointer.
* Skip rc store if rc pointer is NULL.
         BZ    FAILNH_RSN                        Skip rc store.
* Load generic rc for failure.
         L     R7,=F'-1'                         Load generic rc.
* Store rc for caller.
         ST    R7,0(R4)                          Store rc value.
* Check reason pointer before storing error.
FAILNH_RSN LTR   R5,R5                           Test reason pointer.
* Skip reason store if pointer is NULL.
         BZ    DONE                              Skip reason store.
* Load generic reason for failure.
         L     R7,=F'-1'                         Load generic reason.
* Store reason for caller.
         ST    R7,0(R5)                          Store reason value.
* Return via LE epilog.
DONE     CEETERM RC=0                            LE epilog and return.
* Emit literal pool for constants.
         LTORG                                  Emit literal pool.
* Define LE PPA for this routine.
TSOPPA   CEEPPA                                  LE PPA definition.
* Work area layout for caller storage.
WORKAREA DSECT                                  Work area DSECT.
* Saved command pointer.
CMDPTR   DS   F                                 Saved command pointer.
* Saved command length pointer.
CMDLENP  DS   F                                 Saved length pointer.
* Saved return code pointer.
RCPTR    DS   F                                 Saved rc pointer.
* Saved reason pointer.
REASONP  DS   F                                 Saved reason pointer.
* Reserved local rc storage.
LOCALRC  DS   F                                 Local rc storage.
* Reserved local reason storage.
LOCALRSN DS   F                                 Local reason storage.
* IKJEFTSR parameter list storage.
SR_PLIST DS   6F                                IKJEFTSR plist.
* IKJEFTSR flags storage.
SR_FLAGS DS   XL4                               IKJEFTSR flags.
* IKJEFTSR abend code storage.
SR_ABEND DS   F                                 IKJEFTSR abend code.
* Work area size computed from layout.
WORKSIZE EQU  *-WORKAREA                         Work area size.
* LE CAA DSECT anchor (no storage).
CEECAA   DSECT                                  CAA anchor.
* LE CAA layout definition.
         CEECAA                                 CAA layout.
* LE DSA DSECT anchor (no storage).
CEEDSA   DSECT                                  DSA anchor.
* LE DSA layout definition.
         CEEDSA                                 DSA layout.
* CVT anchor for TSVT lookup.
CVTPTR   EQU  16                                 PSA->CVT pointer.
* CVT offset to TVT.
CVTTVT   EQU  X'9C'                              CVT->TVT offset.
* TSO service facility vector table mapping.
         IKJTSVT                                 TSVT layout.
* End of module.
         END
