* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
*
* TSO command wrappers that perform DAIR allocation, command execution,
* and command execution in assembler.
*
* Object Table:
* | Object | Kind | Purpose |
* |--------|------|---------|
* | TSOCMD | CSECT | Allocate DD + run command via IKJEFTSR |
*
* User Actions:
* - Run under TMP (IKJEFT01) so DAIR/TSO services are active.
* - Ensure TSODALC/TSODFRE are available in the link list.
*
* Platform Requirements:
* - LE: required (CEEENTRY/CEETERM).
* - AMODE: 31-bit.
* - EBCDIC: DDNAME and command buffers are EBCDIC.
* - DDNAME I/O: SYSTSPRT redirection via DAIR.
*
* Entry point: TSOCMD (LE-conforming, OS linkage).
* - Purpose: allocate private DD, run IKJEFTSR, capture output, return RC.
* - Input: R1 -> OS plist; plist[0] -> address of parameter block pointer.
* - Parameter block (CMDPARM): CPPL, CMD, CMD_LEN, OUTDD, REASON, ABEND,
*   DAIR_RC, CAT_RC, WORK.
* - Output: R15 RC (IKJEFTSR RC on success; negative on validation errors).
* - RC values: -10..-19 for parameter/DAIR/EFTSI failures; 0+ from IKJEFTSR.
* - Notes: HOB may be set on plist entries; code clears HOB before deref.
* Define entry point control section.
TSOCMD  CEEENTRY PPA=TSCPPA,MAIN=NO,PLIST=OS,PARMREG=1  Enter LE, OS linkage.
* Register aliases.
R0       EQU   0                                   Define register 0 alias.
R1       EQU   1                                   Define register 1 alias.
R2       EQU   2                                   Define register 2 alias.
R3       EQU   3                                   Define register 3 alias.
R4       EQU   4                                   Define register 4 alias.
R5       EQU   5                                   Define register 5 alias.
R6       EQU   6                                   Define register 6 alias.
R7       EQU   7                                   Define register 7 alias.
R8       EQU   8                                   Define register 8 alias.
R9       EQU   9                                   Define register 9 alias.
R10      EQU   10                                  Define register 10 alias.
R11      EQU   11                                  Define register 11 alias.
R12      EQU   12                                  Define register 12 alias.
R13      EQU   13                                  Define register 13 alias.
R14      EQU   14                                  Define register 14 alias.
R15      EQU   15                                  Define register 15 alias.
* External entry points.
         EXTRN TSODALC                              Declare TSODALC entry.
* Set base register for this CSECT.
         LARL  R11,TSOCMD                           Establish module base.
* Enable CAA addressability.
         USING CEECAA,R12                           Map CAA via R12.
* Enable DSA addressability.
         USING CEEDSA,R13                           Map DSA via R13.
* Enable base addressability.
         USING TSOCMD,R11                           Map CSECT via R11.
* Algorithm: validate plist and parameter block pointers before use.
* - Verify plist addressable, slot addressable, and parameter block range.
* Preserve caller parameter list pointer.
         LR    R8,R1                                Save plist pointer in R8.
* Validate caller parameter list pointer.
         LTR   R8,R8                                Test plist pointer for zero.
* Fail when the caller did not provide a parameter pointer.
         BZ    CMD_FAIL_PARM                        Branch on missing plist.
* Verify that the R1 address is translatable (avoid 0C4 on deref).
         LRA   R3,0(R8)                             Check plist addressability.
* Fail when the R1 address is not addressable.
         BNE   CMD_FAIL_PARM                        Branch on bad plist addr.
* Load the first plist entry (slot address with HOB).
         L     R2,0(R8)                             Load slot address from plist.
* Clear the end-of-list high bit from the plist entry.
         N     R2,=X'7FFFFFFF'                      Clear HOB in slot address.
* Validate that the slot address is nonzero.
         LTR   R2,R2                                Test slot address for zero.
* Fail when the slot address is NULL.
         BZ    CMD_FAIL_PARM                        Branch on null slot address.
* Verify that the slot address is addressable.
         LRA   R3,0(R2)                             Check slot addressability.
* Fail when the slot address is not addressable.
         BNE   CMD_FAIL_PARM                        Branch on bad slot address.
* Load the parameter block pointer from the slot.
         L     R2,0(R2)                             Load parameter block pointer.
* Validate that the parameter block pointer is nonzero.
         LTR   R2,R2                                Test parameter block pointer.
* Fail when the parameter block pointer is NULL.
         BZ    CMD_FAIL_PARM                        Branch on null parameter block.
* Verify that the first word of the parameter block is addressable.
         LRA   R3,0(R2)                             Check first word addressability.
* Fail when the parameter block is not addressable.
         BNE   CMD_FAIL_PARM                        Branch on bad parameter block.
* Verify that the last word of the parameter block is addressable.
         LRA   R3,32(R2)                            Check last word addressability.
* Fail when the parameter block crosses an invalid page.
         BNE   CMD_FAIL_PARM                        Branch on invalid block range.
* Parameter block pointer is ready.
CMD_PB_READY DS   0H                                Anchor for parameter-ready path.
* Enable parameter block addressability.
         USING CMDPARM,R2                           Map parameter block via R2.
* Load CPPL pointer from parameter block.
         L     R3,CMD_CPPL                          Load CPPL pointer.
* Validate CPPL pointer.
         LTR   R3,R3                                Test CPPL pointer for zero.
* Fail if CPPL pointer is NULL.
         BZ    CMD_FAIL_CPPL                        Branch on null CPPL pointer.
* Load command pointer from parameter block.
         L     R4,CMD_CMDP                          Load command pointer.
* Validate command pointer.
         LTR   R4,R4                                Test command pointer for zero.
* Fail if command pointer is NULL.
         BZ    CMD_FAIL_CMD                         Branch on null command pointer.
* Load output DDNAME pointer from parameter block.
         L     R5,CMD_OUTDD                         Load DDNAME pointer.
* Validate output DDNAME pointer.
         LTR   R5,R5                                Test DDNAME pointer for zero.
* Fail if output DDNAME pointer is NULL.
         BZ    CMD_FAIL_DD                          Branch on null DDNAME pointer.
* Load DAIR RC pointer from parameter block.
         L     R6,CMD_DAIR                          Load DAIR RC pointer.
* Validate DAIR RC pointer.
         LTR   R6,R6                                Test DAIR RC pointer for zero.
* Fail if DAIR RC pointer is NULL.
         BZ    CMD_FAIL_DAIR                        Branch on null DAIR RC pointer.
* Load CAT RC pointer from parameter block.
         L     R7,CMD_CAT                           Load catalog RC pointer.
* Validate CAT RC pointer.
         LTR   R7,R7                                Test CAT RC pointer for zero.
* Fail if CAT RC pointer is NULL.
         BZ    CMD_FAIL_CAT                         Branch on null CAT RC pointer.
* Load work area pointer from parameter block.
         L     R9,CMD_WORK                          Load work area pointer.
* Validate work area pointer.
         LTR   R9,R9                                Test work area pointer for zero.
* Fail if work area pointer is NULL.
         BZ    CMD_FAIL_WORK                        Branch on null work area pointer.
* Map work area for local storage.
         USING WORKAREA,R9                          Map work area via R9.
* Clear work area block 1/4.
         XC    0(256,R9),0(R9)                      Zero first 256 bytes.
* Clear work area block 2/4.
         XC    256(256,R9),0(R9)                    Zero second 256 bytes.
* Clear work area block 3/4.
         XC    512(256,R9),0(R9)                    Zero third 256 bytes.
* Clear work area block 4/4.
         XC    768(256,R9),0(R9)                    Zero fourth 256 bytes.
* Algorithm: allocate private DD and redirect SYSTSPRT via TSODALC.
* - Build TSODALC plist from local slots and call TSODALC.
* Preserve parameter block pointer across external calls.
* External entry points are not required to preserve R2.
         ST    R2,PBPTRSV                           Save parameter block pointer.
* Store CPPL pointer for TSODALC.
         ST    R3,LOCALCPPL                         Save CPPL pointer for DAIR.
* Store DDNAME pointer for TSODALC.
         ST    R5,LOCALDDN                          Save DDNAME pointer for DAIR.
* Store DAIR RC pointer for TSODALC.
         ST    R6,LOCALDAIR                         Save DAIR RC pointer storage.
* Store CAT RC pointer for TSODALC.
         ST    R7,LOCALCAT                          Save catalog RC pointer storage.
* Compute DAIR work area pointer.
         LA    R10,DAIRWORK                         Compute DAIR work slice address.
* Store DAIR work pointer for TSODALC.
         ST    R10,LOCALWORK                        Save DAIR work pointer.
* Load address of CPPL slot.
         LA    R10,LOCALCPPL                        Address CPPL slot cell.
* Store CPPL slot address in plist.
         ST    R10,DALCPLST                         Store CPPL slot address in plist.
* Load address of DDNAME slot.
         LA    R10,LOCALDDN                         Address DDNAME slot cell.
* Store DDNAME slot address in plist.
         ST    R10,DALCPLST+4                       Store DDNAME slot address.
* Load address of DAIR RC slot.
         LA    R10,LOCALDAIR                        Address DAIR RC slot cell.
* Store DAIR RC slot address in plist.
         ST    R10,DALCPLST+8                       Store DAIR RC slot address.
* Load address of CAT RC slot.
         LA    R10,LOCALCAT                         Address CAT RC slot cell.
* Store CAT RC slot address in plist.
         ST    R10,DALCPLST+12                      Store CAT RC slot address.
* Load address of WORK slot.
         LA    R10,LOCALWORK                        Address work slot cell.
* Mark last plist entry with HOB.
         O     R10,=X'80000000'                     Set end-of-list high bit.
* Store WORK slot address in plist.
         ST    R10,DALCPLST+16                      Store work slot address.
* Point R1 to TSODALC plist.
         LA    R1,DALCPLST                          Point R1 at DAIR plist.
* Load TSODALC entry point.
         L     R15,=V(TSODALC)                      Load TSODALC entry address.
* Call TSODALC to allocate DD.
         BALR  R14,R15                              Call TSODALC allocation.
* Restore parameter block and work area pointers after external call.
         L     R2,PBPTRSV                           Restore parameter block pointer.
         L     R9,CMD_WORK                          Restore work area pointer.
         USING WORKAREA,R9                          Remap work area after call.
* Test TSODALC return code.
         LTR   R15,R15                              Test TSODALC RC.
* Fail if TSODALC returned nonzero.
         BNZ   CMD_FAIL_DALC                        Branch on DAIR failure.
* Reload CPPL pointer after external call.
         L     R3,CMD_CPPL                          Reload CPPL pointer.
*
* Algorithm: initialize IKJEFTSI to obtain an IKJEFTSR token.
* - Build IKJEFTSI parameter list in EFTSIWA and call IKJTSFI.
* Initialize unauthorized TSO service facility environment (IKJEFTSI) and
* obtain a token for the subsequent IKJEFTSR/IKJEFTST calls.
         LA    R10,EFTSIWA                          Address IKJEFTSI work area.
         XC    0(EFTSIWSZ,R10),0(R10)               Zero IKJEFTSI work area.
         LA    R10,EFTSI_ECTPARM@                   Address ECTPARM slot cell.
         ST    R10,EFTSI_ECTPARM@                   Store ECTPARM slot address.
         LA    R10,EFTSI_RESERVED                   Address RESERVED fullword.
         ST    R10,EFTSI_RESERVED@                  Store RESERVED slot address.
         LA    R10,EFTSI_TOKEN                      Address TOKEN field.
         ST    R10,EFTSI_TOKEN@                     Store TOKEN slot address.
         LA    R10,EFTSI_ERROR                      Address ERROR fullword.
         ST    R10,EFTSI_ERROR@                     Store ERROR slot address.
         LA    R10,EFTSI_ABEND                      Address ABEND fullword.
         ST    R10,EFTSI_ABEND@                     Store ABEND slot address.
         LA    R10,EFTSI_REASON                     Address REASON fullword.
         O     R10,=X'80000000'                     Mark end of list (HOB).
         ST    R10,EFTSI_REASON@                    Store last parameter pointer.
         LA    R1,EFTSIWA                           Point R1 at IKJEFTSI plist.
         CALLTSSR EP=IKJTSFI                        Invoke IKJEFTSI.
         ST    R15,EFTRSI_RC                        Save IKJEFTSI return code.
* Fail if IKJEFTSI returned nonzero (token not available).
         LTR   R15,R15                              Test IKJEFTSI RC.
         BNZ   CMD_FAIL_EFTSI                       Branch on IKJEFTSI failure.
* Load command length from parameter block.
         L     R10,CMD_CMDL                         Load command length value.
* Store command length value.
         ST    R10,CMDLENV                          Save command length locally.
* Resolve reason storage pointer.
         L     R10,CMD_REASON                       Load reason pointer.
         LTR   R10,R10                              Test reason pointer for zero.
         BNZ   CMD_RSN_OK                           Branch if reason pointer set.
         LA    R10,REASONV                          Use local reason slot.
CMD_RSN_OK DS 0H                                    Anchor for reason pointer set.
* Resolve abend storage pointer.
         L     R0,CMD_ABEND                         Load abend pointer.
         LTR   R0,R0                                Test abend pointer for zero.
         BNZ   CMD_ABN_OK                           Branch if abend pointer set.
         LA    R0,ABENDV                            Use local abend slot.
CMD_ABN_OK DS 0H                                    Anchor for abend pointer set.
* Algorithm: build IKJEFTSR plist and invoke via TSVTASF.
* - Use caller work slice EFTRWORK for plist and CPPL work area.
* Build IKJEFTSR parameter list in the caller-provided work slice.
         LA    R6,EFTRWORK                          Address IKJEFTSR work slice.
         USING EFTSRWA,R6                           Map IKJEFTSR work layout.
         XC    0(EFTSRWSZ,R6),0(R6)                 Zero IKJEFTSR work slice.
* Set flags for IKJEFTSR (command invocation, unauthorized environment).
         MVI   EFT_FLAGS+0,X'00'                    Clear flag byte 0.
* Unisolated/unauthorized environment.
         MVI   EFT_FLAGS+1,X'01'                    Set unauthorized flag.
         MVI   EFT_FLAGS+2,X'00'                    Clear flag byte 2.
         MVI   EFT_FLAGS+3,X'01'                    Set command invocation flag.
* Store parm1 (flags address).
         LA    R7,EFT_FLAGS                         Address flag bytes.
         ST    R7,EFT_PLIST+0                       Store parm1 address.
* Store parm2 (command string address).
         ST    R4,EFT_PLIST+4                       Store parm2 command pointer.
* Store parm3 (address of fullword length).
         LA    R7,CMDLENV                           Address command length cell.
         ST    R7,EFT_PLIST+8                       Store parm3 address.
* Store parm4 (address of output RC).
         LA    R7,RCVAL                             Address RC output cell.
         ST    R7,EFT_PLIST+12                      Store parm4 address.
* Store parm5 (address of output reason).
         ST    R10,EFT_PLIST+16                     Store parm5 reason pointer.
* Store parm6 (address of output abend code).
         ST    R0,EFT_PLIST+20                      Store parm6 abend pointer.
* Load address of a zero fullword for parm7 (required when parm8/parm9 are used).
         LA    R7,EFT_P7ZERO                        Address zero fullword cell.
* Store parm7 (program parameter list) as address of zero fullword.
         ST    R7,EFT_PLIST+24                      Store parm7 address.
* Store parm8 (CPPL work area). IKJEFTSR may populate this block.
         LA    R7,EFT_CPPL                          Address CPPL work area.
         ST    R7,EFT_PLIST+28                      Store parm8 address.
* Store parm9 (token) from IKJEFTSI and mark end of list (HOB).
         LA    R7,EFTSI_TOKEN                       Address IKJEFTSI token.
         O     R7,=X'80000000'                      Mark end-of-list high bit.
         ST    R7,EFT_PLIST+32                      Store parm9 token address.
* Point R1 to IKJEFTSR parameter list.
         LA    R1,EFT_PLIST                         Point R1 at IKJEFTSR plist.
* Locate TSO service facility entry point (TSVTASF) and invoke IKJEFTSR.
         L     R15,CVTPTR                           Load CVT pointer.
         L     R15,CVTTVT(,R15)                     Load TVT pointer from CVT.
         L     R15,TSVTASF-TSVT(,R15)               Load TSVTASF entry.
         BALR  R14,R15                              Call IKJEFTSR via TSVTASF.
*
* Algorithm: terminate IKJEFTST using token from IKJEFTSI.
* - Build IKJEFTST parameter list and call IKJTSFT.
* Terminate unauthorized TSO service facility environment (IKJEFTST) using
* the token returned by IKJEFTSI.
         LA    R7,EFTSTWA                           Address IKJEFTST work area.
         XC    0(EFTSTWSZ,R7),0(R7)                 Zero IKJEFTST work area.
         LA    R7,EFTST_ECTPARM                     Address ECTPARM fullword.
         ST    R7,EFTST_ECTPARM@                    Store ECTPARM slot address.
         LA    R7,EFTST_RESERVED                    Address RESERVED fullword.
         ST    R7,EFTST_RESERVED@                   Store RESERVED slot address.
         LA    R7,EFTST_TOKEN                       Address TOKEN field.
         ST    R7,EFTST_TOKEN@                      Store TOKEN slot address.
         MVC   EFTST_TOKEN(16),EFTSI_TOKEN          Copy token into IKJEFTST area.
         LA    R7,EFTST_ERROR                       Address ERROR fullword.
         ST    R7,EFTST_ERROR@                      Store ERROR slot address.
         LA    R7,EFTST_ABEND                       Address ABEND fullword.
         ST    R7,EFTST_ABEND@                      Store ABEND slot address.
         LA    R7,EFTST_REASON                      Address REASON fullword.
         O     R7,=X'80000000'                      Mark end of list (HOB).
         ST    R7,EFTST_REASON@                     Store last parameter pointer.
         LA    R1,EFTSTWA                           Point R1 at IKJEFTST plist.
         CALLTSSR EP=IKJTSFT                        Invoke IKJEFTST.
         ST    R15,EFTRST_RC                        Save IKJEFTST return code.
* Drop IKJEFTSR work mapping.
         DROP  R6                                   Drop EFTSRWA mapping.
* Load command RC from local storage.
         L     R15,RCVAL                            Load command RC from local.
* Branch to common return.
         B     CMD_DONE                             Branch to shared return path.
* Fail: parameter block missing.
CMD_FAIL_PARM L  R15,=F'-10'                        Set RC for missing plist.
* Branch to common return.
         B     CMD_DONE                             Branch to shared return path.
* Fail: CPPL pointer missing.
CMD_FAIL_CPPL L  R15,=F'-11'                        Set RC for missing CPPL.
* Branch to common return.
         B     CMD_DONE                             Branch to shared return path.
* Fail: command pointer missing.
CMD_FAIL_CMD L  R15,=F'-12'                         Set RC for missing command.
* Branch to common return.
         B     CMD_DONE                             Branch to shared return path.
* Fail: DDNAME pointer missing.
CMD_FAIL_DD L  R15,=F'-13'                          Set RC for missing DDNAME.
* Branch to common return.
         B     CMD_DONE                             Branch to shared return path.
* Fail: DAIR RC pointer missing.
CMD_FAIL_DAIR L  R15,=F'-14'                        Set RC for missing DAIR RC.
* Branch to common return.
         B     CMD_DONE                             Branch to shared return path.
* Fail: CAT RC pointer missing.
CMD_FAIL_CAT L  R15,=F'-15'                         Set RC for missing CAT RC.
* Branch to common return.
         B     CMD_DONE                             Branch to shared return path.
* Fail: work area missing.
CMD_FAIL_WORK L  R15,=F'-16'                        Set RC for missing work area.
* Branch to common return.
         B     CMD_DONE                             Branch to shared return path.
* Fail: TSODALC reported failure.
CMD_FAIL_DALC L  R15,=F'-18'                        Set RC for TSODALC failure.
* Branch to common return.
         B     CMD_DONE                             Branch to shared return path.
* Fail: IKJEFTSI reported failure.
CMD_FAIL_EFTSI L R15,=F'-19'                        Set RC for IKJEFTSI failure.
* Branch to common return.
         B     CMD_DONE                             Branch to shared return path.
* Return to caller via LE epilog.
CMD_DONE CEETERM RC=(R15)                           Return via LE epilog with RC.
* Emit literal pool for constants.
         LTORG                                      Emit literal pool.
* LE PPA for TSOCMD.
TSCPPA   CEEPPA                                     Define LE PPA for TSOCMD.
* Parameter block layout for TSOCMD.
CMDPARM DSECT                                       Map TSOCMD parameter block.
* CPPL pointer.
CMD_CPPL DS    F                                    CPPL pointer slot.
* Command pointer.
CMD_CMDP DS    F                                    Command pointer slot.
* Command length (fullword).
CMD_CMDL DS    F                                    Command length slot.
* Output DDNAME pointer.
CMD_OUTDD DS   F                                    DDNAME pointer slot.
* Reason pointer.
CMD_REASON DS  F                                    Reason pointer slot.
* Abend pointer.
CMD_ABEND DS   F                                    Abend pointer slot.
* DAIR RC pointer.
CMD_DAIR DS    F                                    DAIR RC pointer slot.
* CAT RC pointer.
CMD_CAT DS     F                                    Catalog RC pointer slot.
* Work area pointer.
CMD_WORK DS    F                                    Work area pointer slot.
* Work area layout for TSOCMD.
WORKAREA DSECT                                      Map TSOCMD work area layout.
* DAIR work area slice.
DAIRWORK DS    CL256                                Reserve DAIR work slice.
* IKJEFTSI work area slice.
EFTSIWA  DS    0F                                   Align IKJEFTSI work area.
EFTSI_ECTPARM@ DS F                                 ECTPARM pointer slot.
EFTSI_RESERVED@ DS F                                RESERVED pointer slot.
EFTSI_TOKEN@ DS F                                   TOKEN pointer slot.
EFTSI_ERROR@ DS F                                   ERROR pointer slot.
EFTSI_ABEND@ DS F                                   ABEND pointer slot.
EFTSI_REASON@ DS F                                  REASON pointer slot.
EFTSI_ECTPARM DS F                                  ECTPARM fullword.
EFTSI_RESERVED DS F                                 RESERVED fullword.
EFTSI_TOKEN DS CL16                                 TOKEN storage (16 bytes).
EFTSI_ERROR DS F                                    ERROR fullword.
EFTSI_ABEND DS F                                    ABEND fullword.
EFTSI_REASON DS F                                   REASON fullword.
EFTSIWSZ EQU  *-EFTSIWA                              IKJEFTSI work size.
* IKJEFTST work area slice.
EFTSTWA  DS    0F                                   Align IKJEFTST work area.
EFTST_ECTPARM@ DS F                                 ECTPARM pointer slot.
EFTST_RESERVED@ DS F                                RESERVED pointer slot.
EFTST_TOKEN@ DS F                                   TOKEN pointer slot.
EFTST_ERROR@ DS F                                   ERROR pointer slot.
EFTST_ABEND@ DS F                                   ABEND pointer slot.
EFTST_REASON@ DS F                                  REASON pointer slot.
EFTST_ECTPARM DS F                                  ECTPARM fullword.
EFTST_RESERVED DS F                                 RESERVED fullword.
EFTST_TOKEN DS CL16                                 TOKEN storage (16 bytes).
EFTST_ERROR DS F                                    ERROR fullword.
EFTST_ABEND DS F                                    ABEND fullword.
EFTST_REASON DS F                                   REASON fullword.
EFTSTWSZ EQU  *-EFTSTWA                              IKJEFTST work size.
* IKJEFTSR work area slice.
EFTRWORK DS    CL152                                Reserve IKJEFTSR work slice.
* CPPL pointer storage.
LOCALCPPL DS   F                                    Local CPPL pointer cell.
* DDNAME pointer storage.
LOCALDDN DS    F                                    Local DDNAME pointer cell.
* DAIR RC pointer storage.
LOCALDAIR DS   F                                    Local DAIR RC pointer cell.
* CAT RC pointer storage.
LOCALCAT DS    F                                    Local catalog RC pointer cell.
* Work pointer storage.
LOCALWORK DS   F                                    Local work pointer cell.
* TSODALC/TSODFRE parameter list.
DALCPLST DS    5F                                   DAIR plist storage.
* Saved parameter block pointer for restore after TSODALC.
PBPTRSV  DS    F                                    Saved parameter block pointer.
* Command length value.
CMDLENV  DS    F                                    Local command length value.
* Command RC value.
RCVAL    DS    F                                    Local command RC value.
* Reason value.
REASONV  DS    F                                    Local reason value.
* Abend value.
ABENDV   DS    F                                    Local abend value.
* Zero fullword used as parm7 placeholder for IKJEFTSR.
EFT_P7ZERO DS  F                                    Zero placeholder for parm7.
* IKJEFTSI return code.
EFTRSI_RC DS   F                                    IKJEFTSI return code storage.
* IKJEFTST return code.
EFTRST_RC DS   F                                    IKJEFTST return code storage.
* Work area size.
WORKSIZE EQU   *-WORKAREA                           Total TSOCMD work size.
* LE CAA DSECT anchor.
CEECAA   DSECT                                      Declare CAA DSECT anchor.
         CEECAA                                     Expand CAA mapping macro.
* LE DSA DSECT anchor.
CEEDSA   DSECT                                      Declare DSA DSECT anchor.
         CEEDSA                                     Expand DSA mapping macro.
* IKJEFTSR work area layout (stored inside WORKAREA.EFTRWORK slice).
EFTSRWA  DSECT                                      Map IKJEFTSR work layout.
* IKJEFTSR parameter list (flags, cmd, len, rc, reason, abend, parm7, cppl, token).
EFT_PLIST DS   9F                                   IKJEFTSR parameter list.
* IKJEFTSR flags (4 bytes).
EFT_FLAGS DS   XL4                                  IKJEFTSR flag bytes.
* IKJEFTSR CPPL work area (4 fullwords).
EFT_CPPL  DS   4F                                   IKJEFTSR CPPL work area.
* IKJEFTSI/IKJEFTSR token storage (16 bytes).
EFT_TOKEN DS   CL16                                 Token storage for IKJEFTSR.
* Work area size computed from layout.
EFTSRWSZ EQU   *-EFTSRWA                             IKJEFTSR work size.
* CVT/TVT offsets for locating TSVTASF (TSO service facility).
CVTPTR   EQU   16                                   CVT pointer offset.
CVTTVT   EQU   X'9C'                                CVT-to-TVT offset.
         IKJTSVT                                    Map TSVT control block.
* End of TSOCMD module.
         END   TSOCMD                               End of TSOCMD CSECT.
