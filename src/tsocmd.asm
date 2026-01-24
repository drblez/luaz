* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
*
* TSO command wrappers that perform DAIR allocation, command
* execution,
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
* - Purpose: allocate private DD, run IKJEFTSR, capture output, return
* RC.
* - Input: R1 -> OS plist; plist[0] -> parameter block pointer value.
* - Parameter block (CMDPARM): CPPL, CMD, CMD_LEN, OUTDD, REASON,
* ABEND,
*   DAIR_RC, CAT_RC, WORK.
* - Output: R15 RC (IKJEFTSR RC on success; negative on validation
* errors).
* - RC values: -10..-19 for parameter/DAIR/EFTSI failures; 0+ from
* IKJEFTSR.
* - Notes: HOB may be set on plist entries; code clears HOB before
* deref.
* Change note: align TSOCMD with LE_C_HLASM_RULES for CSECT/base/HOB.
* Problem: missing stable CEEENTRY base and literal-based HOB masking.
* Expected effect: stable addressability and correct plist pointer
* handling.
* Impact: TSOCMD uses CEEENTRY base and NILF for HOB.
* Define entry point control section.
TSOCMD  CSECT
* Change note: keep AMODE/RMODE on CEEENTRY to avoid ASMA186E
* duplicates.
* Problem: standalone AMODE/RMODE conflicts with CEEENTRY expansion.
* Expected effect: ASMA90 RC=0 with CEEENTRY-controlled modes.
* Impact: AMODE/RMODE set via CEEENTRY.
* Ref: src/tsocmd.md#ceeentry-amode-rmode
* Change note: fix CEEENTRY continuation column for AMODE/RMODE.
* Problem: wrong continuation column triggered ASMA145E.
* Expected effect: CEEENTRY macro parses AMODE/RMODE correctly.
* Enter LE, OS linkage for TSOCMD entry.
TSOCMD  CEEENTRY PPA=TSCPPA,MAIN=NO,AUTO=4,PLIST=OS,PARMREG=1,         X
               BASE=(11),AMODE=31,RMODE=ANY
* Register aliases.
* Define register 0 alias.
R0       EQU   0
* Define register 1 alias.
R1       EQU   1
* Define register 2 alias.
R2       EQU   2
* Define register 3 alias.
R3       EQU   3
* Define register 4 alias.
R4       EQU   4
* Define register 5 alias.
R5       EQU   5
* Define register 6 alias.
R6       EQU   6
* Define register 7 alias.
R7       EQU   7
* Define register 8 alias.
R8       EQU   8
* Define register 9 alias.
R9       EQU   9
* Define register 10 alias.
R10      EQU   10
* Define register 11 alias.
R11      EQU   11
* Define register 12 alias.
R12      EQU   12
* Define register 13 alias.
R13      EQU   13
* Define register 14 alias.
R14      EQU   14
* Define register 15 alias.
R15      EQU   15
* External entry points.
* Declare TSODALC entry.
         EXTRN TSODALC
* Enable CAA addressability.
         USING CEECAA,R12                           Map CAA via R12.
* Enable DSA addressability.
         USING CEEDSA,R13                           Map DSA via R13.
* Enable base addressability from CEEENTRY base register.
         USING TSOCMD,R11                           Map CSECT via R11.
* Algorithm: validate plist and parameter block pointers before use.
* Change note: remove LRA addressability probes for TSOCMD.
* Problem: LRA causes 0C2 in problem state under TMP.
* Expected effect: TSOCMD no longer issues privileged checks;
* allows runtime behavior to be validated per LE_C_HLASM_RULES.
* Impact: only NULL checks remain before dereference.
* - Validate plist and parameter block pointers for NULL only.
* Preserve caller parameter list pointer.
* Save plist pointer in R8.
         LR    R8,R1
* Validate caller parameter list pointer.
* Test plist pointer for zero.
         LTR   R8,R8
* Fail when the caller did not provide a parameter pointer.
* Branch on missing plist.
         BZ    CMD_FAIL_PARM
* Load the parameter block pointer from the plist entry (with HOB).
* Load parameter block pointer from plist entry.
         L     R2,0(R8)
* Clear the end-of-list high bit from the plist entry.
* Clear HOB in parameter block pointer.
         NILF  R2,X'7FFFFFFF'                       Clear HOB via NILF.
* Validate that the parameter block pointer is nonzero.
* Test parameter block pointer for zero.
         LTR   R2,R2
* Fail when the parameter block pointer is NULL.
* Branch on null parameter block.
         BZ    CMD_FAIL_PARM
* Parameter block pointer is ready.
* Anchor for parameter-ready path.
CMD_PB_READY DS   0H
* Enable parameter block addressability.
* Map parameter block via R2.
         USING CMDPARM,R2
* Load CPPL pointer from parameter block.
         L     R3,CMD_CPPL                          Load CPPL pointer.
* Validate CPPL pointer.
* Test CPPL pointer for zero.
         LTR   R3,R3
* Fail if CPPL pointer is NULL.
* Branch on null CPPL pointer.
         BZ    CMD_FAIL_CPPL
* Load command pointer from parameter block.
* Load command pointer.
         L     R4,CMD_CMDP
* Validate command pointer.
* Test command pointer for zero.
         LTR   R4,R4
* Fail if command pointer is NULL.
* Branch on null command pointer.
         BZ    CMD_FAIL_CMD
* Load output DDNAME pointer from parameter block.
* Load DDNAME pointer.
         L     R5,CMD_OUTDD
* Validate output DDNAME pointer.
* Test DDNAME pointer for zero.
         LTR   R5,R5
* Fail if output DDNAME pointer is NULL.
* Branch on null DDNAME pointer.
         BZ    CMD_FAIL_DD
* Load DAIR RC pointer from parameter block.
* Load DAIR RC pointer.
         L     R6,CMD_DAIR
* Validate DAIR RC pointer.
* Test DAIR RC pointer for zero.
         LTR   R6,R6
* Fail if DAIR RC pointer is NULL.
* Branch on null DAIR RC pointer.
         BZ    CMD_FAIL_DAIR
* Load CAT RC pointer from parameter block.
* Load catalog RC pointer.
         L     R7,CMD_CAT
* Validate CAT RC pointer.
* Test CAT RC pointer for zero.
         LTR   R7,R7
* Fail if CAT RC pointer is NULL.
* Branch on null CAT RC pointer.
         BZ    CMD_FAIL_CAT
* Load work area pointer from parameter block.
* Load work area pointer.
         L     R9,CMD_WORK
* Validate work area pointer.
* Test work area pointer for zero.
         LTR   R9,R9
* Fail if work area pointer is NULL.
* Branch on null work area pointer.
         BZ    CMD_FAIL_WORK
* Map work area for local storage.
* Map work area via R9.
         USING WORKAREA,R9
* Clear work area block 1/4.
* Zero first 256 bytes.
         XC    0(256,R9),0(R9)
* Clear work area block 2/4.
* Zero second 256 bytes.
         XC    256(256,R9),0(R9)
* Clear work area block 3/4.
* Zero third 256 bytes.
         XC    512(256,R9),0(R9)
* Clear work area block 4/4.
* Zero fourth 256 bytes.
         XC    768(256,R9),0(R9)
* Change note: preserve parameter block pointer in DSA auto storage.
* Problem: TSODALC may clobber R9/R2; reloading PBPTRSV via R9 fails.
* Expected effect: restore parameter block pointer via CEEDSAAUTO.
* Impact: uses AUTO=4 storage in LE DSA, no work area dependency.
* Ref: src/tsocmd.md#ceeentry-auto
* Algorithm: allocate private DD and redirect SYSTSPRT via TSODALC.
* - Build TSODALC plist from local slots and call TSODALC.
* Preserve parameter block pointer across external calls.
* External entry points are not required to preserve R2.
* Save parameter block pointer in DSA automatic storage.
         ST    R2,CEEDSAAUTO
* Store CPPL pointer for TSODALC.
* Save CPPL pointer for DAIR.
         ST    R3,LOCALCPPL
* Store DDNAME pointer for TSODALC.
* Save DDNAME pointer for DAIR.
         ST    R5,LOCALDDN
* Store DAIR RC pointer for TSODALC.
* Save DAIR RC pointer storage.
         ST    R6,LOCALDAIR
* Store CAT RC pointer for TSODALC.
* Save catalog RC pointer storage.
         ST    R7,LOCALCAT
* Compute DAIR work area pointer.
* Compute DAIR work slice address.
         LA    R10,DAIRWORK
* Store DAIR work pointer for TSODALC.
* Save DAIR work pointer.
         ST    R10,LOCALWORK
* Load address of CPPL slot.
* Address CPPL slot cell.
         LA    R10,LOCALCPPL
* Store CPPL slot address in plist.
* Store CPPL slot address in plist.
         ST    R10,DALCPLST
* Load address of DDNAME slot.
* Address DDNAME slot cell.
         LA    R10,LOCALDDN
* Store DDNAME slot address in plist.
* Store DDNAME slot address.
         ST    R10,DALCPLST+4
* Load address of DAIR RC slot.
* Address DAIR RC slot cell.
         LA    R10,LOCALDAIR
* Store DAIR RC slot address in plist.
* Store DAIR RC slot address.
         ST    R10,DALCPLST+8
* Load address of CAT RC slot.
* Address CAT RC slot cell.
         LA    R10,LOCALCAT
* Store CAT RC slot address in plist.
* Store CAT RC slot address.
         ST    R10,DALCPLST+12
* Load address of WORK slot.
* Address work slot cell.
         LA    R10,LOCALWORK
* Mark last plist entry with HOB.
* Set end-of-list high bit.
         O     R10,=X'80000000'
* Store WORK slot address in plist.
* Store work slot address.
         ST    R10,DALCPLST+16
* Point R1 to TSODALC plist.
* Point R1 at DAIR plist.
         LA    R1,DALCPLST
* Load TSODALC entry point.
* Load TSODALC entry address.
         L     R15,=V(TSODALC)
* Call TSODALC to allocate DD.
* Call TSODALC allocation.
         BALR  R14,R15
* Restore parameter block pointer after external call.
         L     R2,CEEDSAAUTO
* Restore work area pointer.
         L     R9,CMD_WORK
* Remap work area after call.
         USING WORKAREA,R9
* Test TSODALC return code.
         LTR   R15,R15                              Test TSODALC RC.
* Fail if TSODALC returned nonzero.
* Branch on DAIR failure.
         BNZ   CMD_FAIL_DALC
* Reload CPPL pointer after external call.
* Reload CPPL pointer.
         L     R3,CMD_CPPL
*
* Algorithm: initialize IKJEFTSI to obtain an IKJEFTSR token.
* - Build IKJEFTSI parameter list in EFTSIWA and call IKJTSFI.
* Initialize unauthorized TSO service facility environment (IKJEFTSI)
* and
* obtain a token for the subsequent IKJEFTSR/IKJEFTST calls.
* Address IKJEFTSI work area.
         LA    R10,EFTSIWA
* Zero IKJEFTSI work area.
         XC    0(EFTSIWSZ,R10),0(R10)
* Address ECTPARM slot cell.
         LA    R10,EFTSI_ECTPARM@
* Store ECTPARM slot address.
         ST    R10,EFTSI_ECTPARM@
* Address RESERVED fullword.
         LA    R10,EFTSI_RESERVED
* Store RESERVED slot address.
         ST    R10,EFTSI_RESERVED@
* Address TOKEN field.
         LA    R10,EFTSI_TOKEN
* Store TOKEN slot address.
         ST    R10,EFTSI_TOKEN@
* Address ERROR fullword.
         LA    R10,EFTSI_ERROR
* Store ERROR slot address.
         ST    R10,EFTSI_ERROR@
* Address ABEND fullword.
         LA    R10,EFTSI_ABEND
* Store ABEND slot address.
         ST    R10,EFTSI_ABEND@
* Address REASON fullword.
         LA    R10,EFTSI_REASON
* Mark end of list (HOB).
         O     R10,=X'80000000'
* Store last parameter pointer.
         ST    R10,EFTSI_REASON@
* Point R1 at IKJEFTSI plist.
         LA    R1,EFTSIWA
         CALLTSSR EP=IKJTSFI                        Invoke IKJEFTSI.
* Save IKJEFTSI return code.
         ST    R15,EFTRSI_RC
* Fail if IKJEFTSI returned nonzero (token not available).
         LTR   R15,R15                              Test IKJEFTSI RC.
* Branch on IKJEFTSI failure.
         BNZ   CMD_FAIL_EFTSI
* Load command length from parameter block.
* Load command length value.
         L     R10,CMD_CMDL
* Store command length value.
* Save command length locally.
         ST    R10,CMDLENV
* Resolve reason storage pointer.
* Load reason pointer.
         L     R10,CMD_REASON
* Test reason pointer for zero.
         LTR   R10,R10
* Branch if reason pointer set.
         BNZ   CMD_RSN_OK
* Use local reason slot.
         LA    R10,REASONV
* Anchor for reason pointer set.
CMD_RSN_OK DS 0H
* Resolve abend storage pointer.
* Load abend pointer.
         L     R0,CMD_ABEND
* Test abend pointer for zero.
         LTR   R0,R0
* Branch if abend pointer set.
         BNZ   CMD_ABN_OK
* Use local abend slot.
         LA    R0,ABENDV
* Anchor for abend pointer set.
CMD_ABN_OK DS 0H
* Algorithm: build IKJEFTSR plist and invoke via TSVTASF.
* - Use caller work slice EFTRWORK for plist and CPPL work area.
* Build IKJEFTSR parameter list in the caller-provided work slice.
* Address IKJEFTSR work slice.
         LA    R6,EFTRWORK
* Map IKJEFTSR work layout.
         USING EFTSRWA,R6
* Zero IKJEFTSR work slice.
         XC    0(EFTSRWSZ,R6),0(R6)
* Set flags for IKJEFTSR (command invocation, unauthorized
* environment).
         MVI   EFT_FLAGS+0,X'00'                    Clear flag byte 0.
* Unisolated/unauthorized environment.
* Set unauthorized flag.
         MVI   EFT_FLAGS+1,X'01'
         MVI   EFT_FLAGS+2,X'00'                    Clear flag byte 2.
* Set command invocation flag.
         MVI   EFT_FLAGS+3,X'01'
* Store parm1 (flags address).
* Address flag bytes.
         LA    R7,EFT_FLAGS
* Store parm1 address.
         ST    R7,EFT_PLIST+0
* Store parm2 (command string address).
* Store parm2 command pointer.
         ST    R4,EFT_PLIST+4
* Store parm3 (address of fullword length).
* Address command length cell.
         LA    R7,CMDLENV
* Store parm3 address.
         ST    R7,EFT_PLIST+8
* Store parm4 (address of output RC).
* Address RC output cell.
         LA    R7,RCVAL
* Store parm4 address.
         ST    R7,EFT_PLIST+12
* Store parm5 (address of output reason).
* Store parm5 reason pointer.
         ST    R10,EFT_PLIST+16
* Store parm6 (address of output abend code).
* Store parm6 abend pointer.
         ST    R0,EFT_PLIST+20
* Load address of a zero fullword for parm7 (required when parm8/parm9
* are used).
* Address zero fullword cell.
         LA    R7,EFT_P7ZERO
* Store parm7 (program parameter list) as address of zero fullword.
* Store parm7 address.
         ST    R7,EFT_PLIST+24
* Store parm8 (CPPL work area). IKJEFTSR may populate this block.
* Address CPPL work area.
         LA    R7,EFT_CPPL
* Store parm8 address.
         ST    R7,EFT_PLIST+28
* Store parm9 (token) from IKJEFTSI and mark end of list (HOB).
* Address IKJEFTSI token.
         LA    R7,EFTSI_TOKEN
* Mark end-of-list high bit.
         O     R7,=X'80000000'
* Store parm9 token address.
         ST    R7,EFT_PLIST+32
* Point R1 to IKJEFTSR parameter list.
* Point R1 at IKJEFTSR plist.
         LA    R1,EFT_PLIST
* Locate TSO service facility entry point (TSVTASF) and invoke
* IKJEFTSR.
         L     R15,CVTPTR                           Load CVT pointer.
* Load TVT pointer from CVT.
         L     R15,CVTTVT(,R15)
* Load TSVTASF entry.
         L     R15,TSVTASF-TSVT(,R15)
* Call IKJEFTSR via TSVTASF.
         BALR  R14,R15
*
* Algorithm: terminate IKJEFTST using token from IKJEFTSI.
* - Build IKJEFTST parameter list and call IKJTSFT.
* Terminate unauthorized TSO service facility environment (IKJEFTST)
* using
* the token returned by IKJEFTSI.
* Address IKJEFTST work area.
         LA    R7,EFTSTWA
* Zero IKJEFTST work area.
         XC    0(EFTSTWSZ,R7),0(R7)
* Address ECTPARM fullword.
         LA    R7,EFTST_ECTPARM
* Store ECTPARM slot address.
         ST    R7,EFTST_ECTPARM@
* Address RESERVED fullword.
         LA    R7,EFTST_RESERVED
* Store RESERVED slot address.
         ST    R7,EFTST_RESERVED@
* Address TOKEN field.
         LA    R7,EFTST_TOKEN
* Store TOKEN slot address.
         ST    R7,EFTST_TOKEN@
* Copy token into IKJEFTST area.
         MVC   EFTST_TOKEN(16),EFTSI_TOKEN
* Address ERROR fullword.
         LA    R7,EFTST_ERROR
* Store ERROR slot address.
         ST    R7,EFTST_ERROR@
* Address ABEND fullword.
         LA    R7,EFTST_ABEND
* Store ABEND slot address.
         ST    R7,EFTST_ABEND@
* Address REASON fullword.
         LA    R7,EFTST_REASON
* Mark end of list (HOB).
         O     R7,=X'80000000'
* Store last parameter pointer.
         ST    R7,EFTST_REASON@
* Point R1 at IKJEFTST plist.
         LA    R1,EFTSTWA
         CALLTSSR EP=IKJTSFT                        Invoke IKJEFTST.
* Save IKJEFTST return code.
         ST    R15,EFTRST_RC
* Drop IKJEFTSR work mapping.
* Drop EFTSRWA mapping.
         DROP  R6
* Load command RC from local storage.
* Load command RC from local.
         L     R15,RCVAL
* Branch to common return.
* Branch to shared return path.
         B     CMD_DONE
* Fail: parameter block missing.
* Set RC for missing plist.
CMD_FAIL_PARM L  R15,=F'-10'
* Branch to common return.
* Branch to shared return path.
         B     CMD_DONE
* Fail: CPPL pointer missing.
* Set RC for missing CPPL.
CMD_FAIL_CPPL L  R15,=F'-11'
* Branch to common return.
* Branch to shared return path.
         B     CMD_DONE
* Fail: command pointer missing.
* Set RC for missing command.
CMD_FAIL_CMD L  R15,=F'-12'
* Branch to common return.
* Branch to shared return path.
         B     CMD_DONE
* Fail: DDNAME pointer missing.
* Set RC for missing DDNAME.
CMD_FAIL_DD L  R15,=F'-13'
* Branch to common return.
* Branch to shared return path.
         B     CMD_DONE
* Fail: DAIR RC pointer missing.
* Set RC for missing DAIR RC.
CMD_FAIL_DAIR L  R15,=F'-14'
* Branch to common return.
* Branch to shared return path.
         B     CMD_DONE
* Fail: CAT RC pointer missing.
* Set RC for missing CAT RC.
CMD_FAIL_CAT L  R15,=F'-15'
* Branch to common return.
* Branch to shared return path.
         B     CMD_DONE
* Fail: work area missing.
* Set RC for missing work area.
CMD_FAIL_WORK L  R15,=F'-16'
* Branch to common return.
* Branch to shared return path.
         B     CMD_DONE
* Fail: TSODALC reported failure.
* Set RC for TSODALC failure.
CMD_FAIL_DALC L  R15,=F'-18'
* Branch to common return.
* Branch to shared return path.
         B     CMD_DONE
* Fail: IKJEFTSI reported failure.
* Set RC for IKJEFTSI failure.
CMD_FAIL_EFTSI L R15,=F'-19'
* Branch to common return.
* Branch to shared return path.
         B     CMD_DONE
* Return to caller via LE epilog.
* Return via LE epilog with RC.
CMD_DONE CEETERM RC=(R15)
* Emit literal pool for constants.
         LTORG                                      Emit literal pool.
* LE PPA for TSOCMD.
* Define LE PPA for TSOCMD.
TSCPPA   CEEPPA
* Parameter block layout for TSOCMD.
* Map TSOCMD parameter block.
CMDPARM DSECT
* CPPL pointer.
CMD_CPPL DS    F                                    CPPL pointer slot.
* Command pointer.
* Command pointer slot.
CMD_CMDP DS    F
* Command length (fullword).
* Command length slot.
CMD_CMDL DS    F
* Output DDNAME pointer.
* DDNAME pointer slot.
CMD_OUTDD DS   F
* Reason pointer.
* Reason pointer slot.
CMD_REASON DS  F
* Abend pointer.
* Abend pointer slot.
CMD_ABEND DS   F
* DAIR RC pointer.
* DAIR RC pointer slot.
CMD_DAIR DS    F
* CAT RC pointer.
* Catalog RC pointer slot.
CMD_CAT DS     F
* Work area pointer.
* Work area pointer slot.
CMD_WORK DS    F
* Work area layout for TSOCMD.
* Map TSOCMD work area layout.
WORKAREA DSECT
* DAIR work area slice.
* Reserve DAIR work slice.
DAIRWORK DS    CL256
* IKJEFTSI work area slice.
* Align IKJEFTSI work area.
EFTSIWA  DS    0F
* ECTPARM pointer slot.
EFTSI_ECTPARM@ DS F
* RESERVED pointer slot.
EFTSI_RESERVED@ DS F
* TOKEN pointer slot.
EFTSI_TOKEN@ DS F
* ERROR pointer slot.
EFTSI_ERROR@ DS F
* ABEND pointer slot.
EFTSI_ABEND@ DS F
* REASON pointer slot.
EFTSI_REASON@ DS F
EFTSI_ECTPARM DS F                                  ECTPARM fullword.
EFTSI_RESERVED DS F                                 RESERVED fullword.
* TOKEN storage (16 bytes).
EFTSI_TOKEN DS CL16
EFTSI_ERROR DS F                                    ERROR fullword.
EFTSI_ABEND DS F                                    ABEND fullword.
EFTSI_REASON DS F                                   REASON fullword.
* IKJEFTSI work size.
EFTSIWSZ EQU  *-EFTSIWA
* IKJEFTST work area slice.
* Align IKJEFTST work area.
EFTSTWA  DS    0F
* ECTPARM pointer slot.
EFTST_ECTPARM@ DS F
* RESERVED pointer slot.
EFTST_RESERVED@ DS F
* TOKEN pointer slot.
EFTST_TOKEN@ DS F
* ERROR pointer slot.
EFTST_ERROR@ DS F
* ABEND pointer slot.
EFTST_ABEND@ DS F
* REASON pointer slot.
EFTST_REASON@ DS F
EFTST_ECTPARM DS F                                  ECTPARM fullword.
EFTST_RESERVED DS F                                 RESERVED fullword.
* TOKEN storage (16 bytes).
EFTST_TOKEN DS CL16
EFTST_ERROR DS F                                    ERROR fullword.
EFTST_ABEND DS F                                    ABEND fullword.
EFTST_REASON DS F                                   REASON fullword.
* IKJEFTST work size.
EFTSTWSZ EQU  *-EFTSTWA
* IKJEFTSR work area slice.
* Reserve IKJEFTSR work slice.
EFTRWORK DS    CL152
* CPPL pointer storage.
* Local CPPL pointer cell.
LOCALCPPL DS   F
* DDNAME pointer storage.
* Local DDNAME pointer cell.
LOCALDDN DS    F
* DAIR RC pointer storage.
* Local DAIR RC pointer cell.
LOCALDAIR DS   F
* CAT RC pointer storage.
* Local catalog RC pointer cell.
LOCALCAT DS    F
* Work pointer storage.
* Local work pointer cell.
LOCALWORK DS   F
* TSODALC/TSODFRE parameter list.
* DAIR plist storage.
DALCPLST DS    5F
* Saved parameter block pointer for restore after TSODALC.
* Saved parameter block pointer.
PBPTRSV  DS    F
* Command length value.
* Local command length value.
CMDLENV  DS    F
* Command RC value.
* Local command RC value.
RCVAL    DS    F
* Reason value.
* Local reason value.
REASONV  DS    F
* Abend value.
ABENDV   DS    F                                    Local abend value.
* Zero fullword used as parm7 placeholder for IKJEFTSR.
* Zero placeholder for parm7.
EFT_P7ZERO DS  F
* IKJEFTSI return code.
* IKJEFTSI return code storage.
EFTRSI_RC DS   F
* IKJEFTST return code.
* IKJEFTST return code storage.
EFTRST_RC DS   F
* Work area size.
* Total TSOCMD work size.
WORKSIZE EQU   *-WORKAREA
* LE CAA DSECT anchor.
* Declare CAA DSECT anchor.
CEECAA   DSECT
* Expand CAA mapping macro.
         CEECAA
* LE DSA DSECT anchor.
* Declare DSA DSECT anchor.
CEEDSA   DSECT
* Expand DSA mapping macro.
         CEEDSA
* IKJEFTSR work area layout (stored inside WORKAREA.EFTRWORK slice).
* Map IKJEFTSR work layout.
EFTSRWA  DSECT
* IKJEFTSR parameter list (flags, cmd, len, rc, reason, abend, parm7,
* cppl, token).
* IKJEFTSR parameter list.
EFT_PLIST DS   9F
* IKJEFTSR flags (4 bytes).
* IKJEFTSR flag bytes.
EFT_FLAGS DS   XL4
* IKJEFTSR CPPL work area (4 fullwords).
* IKJEFTSR CPPL work area.
EFT_CPPL  DS   4F
* IKJEFTSI/IKJEFTSR token storage (16 bytes).
* Token storage for IKJEFTSR.
EFT_TOKEN DS   CL16
* Work area size computed from layout.
* IKJEFTSR work size.
EFTSRWSZ EQU   *-EFTSRWA
* CVT/TVT offsets for locating TSVTASF (TSO service facility).
* CVT pointer offset.
CVTPTR   EQU   16
CVTTVT   EQU   X'9C'                                CVT-to-TVT offset.
* Map TSVT control block.
         IKJTSVT
* End of TSOCMD module.
* End of TSOCMD CSECT.
         END   TSOCMD
