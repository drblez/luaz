* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
*
* DAIR ASM wrappers for temporary DD allocation without SYSTSPRT
* redirection.
*
* Object Table:
* | Object  | Kind  | Purpose |
* |---------|-------|---------|
* | TSODALO | CSECT | Allocate private DD only (no SYSTSPRT) |
* | TSODFLO | CSECT | Free private DD allocation only |
*
* User Actions:
* - Run under TMP (IKJEFT01) so DAIR is available.
* - Ensure IKJDAIR is available in the current TSO/E environment.
*
* Platform Requirements:
* - LE: required (CEEENTRY/CEETERM).
* - AMODE: 31-bit (TMP/TSO services).
* - EBCDIC: DDNAME/DSNAME fields are EBCDIC.
* - DDNAME I/O: private DDNAME is allocated for STACK OUTDD usage.
*
* Emit assembler listing for debug.
         PRINT GEN
* Declare IKJDAIR external entry.
         EXTRN IKJDAIR
* Change note: allocate OUTDD via DAIR without redirecting SYSTSPRT.
* Problem: STACK OUTDD fails when SYSTSPRT is reallocated by DAIR.
* Expected effect: private DDNAME is available for STACK OUTDD only.
* Impact: tso.cmd captures output via STACK without SYSOUT DDNAME.
* Ref: src/tsodalo.asm.md#dair-outdd-only
* -------------------------------------------------------------
* Entry point: TSODALO (LE-conforming, OS linkage).
* - Purpose: allocate private DD for OUTDD capture (no SYSTSPRT).
* - Input: R1 -> OS plist with 3 entries (cppl, ddname, work).
* - Output: R15 RC (0 success; 8 DAIR failure; 12-17 invalid inputs).
* - Notes: ddname points to 8-byte EBCDIC DDNAME; work size >=
* WORKSIZE.
* -------------------------------------------------------------
* Define TSODALO control section.
TSODALO  CSECT
* Enter LE with OS plist (AMODE/RMODE set via CEEENTRY).
TSODALO  CEEENTRY PPA=TSDPPA1,MAIN=NO,PLIST=OS,PARMREG=1,BASE=(11),    X
               AMODE=31,RMODE=ANY
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
* Algorithm: validate plist entries and map required control blocks.
* - Validate cppl, ddname, and work pointer.
* - Map WORKAREA, DAPL, DAPB08, CPPL.
* Establish CSECT base register from CEEENTRY.
         USING TSODALO,R11
* Enable CAA addressability.
         USING CEECAA,R12
* Enable DSA addressability.
         USING CEEDSA,R13
* Preserve caller plist pointer.
         LR    R8,R1
* Load CPPL pointer value.
         L     R2,0(R8)
* Validate CPPL pointer.
         LTR   R2,R2
* Branch if CPPL pointer is NULL.
         BZ    TDALO_FAIL_CPPL
* Load DDNAME pointer value.
         L     R3,4(R8)
* Validate DDNAME pointer.
         LTR   R3,R3
* Branch if DDNAME pointer is NULL.
         BZ    TDALO_FAIL_DDNAME
* Load work pointer value.
         L     R0,8(R8)
* Clear end-of-plist high bit on work pointer.
         NILF  R0,X'7FFFFFFF'  Clear HOB via NILF.
* Check work pointer for NULL.
         LTR   R0,R0
* Branch if work area pointer is NULL.
         BZ    TDALO_FAIL_WORK
* Use caller work area base.
         LR    R9,R0
* Map work area for fields.
         USING WORKAREA,R9
* Algorithm: build DAPL/DAPB08 for private DD allocation.
* - Construct DSNAME &&LZ<DDNAME>, set DCB attributes via DAIR list.
* Clear work area to defaults (split to stay within XC length limits).
         XC    0(WORKSZ1,R9),0(R9)
         XC    WORKSZ1(WORKSZ2,R9),WORKSZ1(R9)
* Change note: preserve WORKAREA base across DAIR calls.
* Problem: IKJDAIR can clobber registers including R9.
* Expected effect: R9 is restored before accessing WORKAREA fields.
* Impact: prevents 0C4 when storing DAIR outputs.
* Ref: src/tsodalo.asm.md#dair-outdd-only
* Save WORKAREA base for later reload.
         ST    R9,WORKPTR
* Load DAPL base address.
         LA    R8,DAPLAREA
* Map DAPL fields with base.
         USING DAPL,R8
* Load DAPB08 base address.
         LA    R6,DAPB08AREA
* Map DAPB08 fields with base.
         USING DAPB08,R6
* Load DAPB34 base address.
         LA    R14,DAPB34AREA
* Map DAPB34 fields with base.
         USING DAPB34,R14
* Change note: map DAIRACB with a nonzero base register.
* Problem: R0 as base causes DAIRACB XC to abend with 0C4.
* Expected effect: DAIRACB clears use a valid base register.
* Impact: TSODALO attribute list setup no longer abends.
* Ref: src/tsodalo.asm.md#dair-attr-list
* Load DAIRACB base address.
         LA    R1,DAIRACBAREA
* Map DAIRACB fields with base.
         USING DAIRACB,R1
* Copy caller DDNAME (8 chars).
         MVC   DDNAME(8),0(R3)
* Blank-fill DSNAME area.
         MVC   DSNBUF+2(44),BLANKS
* Change note: use fixed-length DAIR utility DSNAME "&LUAZ000".
* Problem: DAIR X'08' rejects utility names longer than 8 bytes.
* Expected effect: DAIR allocates &LUAZ000 as a utility dataset.
* Impact: DDNAME becomes visible to STACK and fopen.
* Ref: src/tsodalo.asm.md#dair-utility-name
* Set DSNAME prefix "&".
         MVC   DSNBUF+2(1),DSNPFX
* Append fixed utility suffix.
         MVC   DSNBUF+3(7),DSNALT
* Load DSNAME length (8).
         LA    R7,8
* Store DSNAME length.
         STH   R7,DSNBUF
* Copy CPPL pointer to base.
         LR    R10,R2
* Map CPPL control block.
         USING CPPL,R10
* Load UPT pointer from CPPL.
         L     R7,CPPLUPT
* Store UPT pointer in DAPL.
         ST    R7,DAPLUPT
* Load ECT pointer from CPPL.
         L     R7,CPPLECT
* Store ECT pointer in DAPL.
         ST    R7,DAPLECT
* Change note: provide a valid ECB pointer in DAPL for DAIR calls.
* Problem: DAPLECB left zero can make DAIR reject the parameter list.
* Expected effect: DAIR accepts the DAPL and proceeds with allocation.
* Impact: X'08' no longer returns RC=4 for invalid parameters.
* Ref: src/tsodalo.asm.md#dair-daplecb
* Load ECB storage address from WORKAREA.
         LA    R7,ECBWORD
* Store ECB pointer in DAPL.
         ST    R7,DAPLECB
* Load PSCB pointer from CPPL.
         L     R7,CPPLPSCB
* Store PSCB pointer in DAPL.
         ST    R7,DAPLPSCB
* Change note: build DAIR attribute list for OUTDD DCB parameters.
* Problem: copying DCB from SYSOUT-backed DDNAME left STACK OUTDD
* unopened.
* Expected effect: attribute list supplies explicit DCB to DAIR
* allocate.
* Impact: STACK OUTDD can open the allocated temp dataset.
* Ref: src/tsodalo.asm.md#dair-attr-list
* Store DAPB34 pointer in DAPL.
         ST    R14,DAPLDAPB
* Clear DAPB34 request block.
         XC    0(DAPB34_LEN,R14),0(R14)
* Set DAIR entry code X'34'.
         MVC   DA34CD,=X'0034'
* Build and chain the attribute list.
         MVI   DA34CTRL,DA34CHN
* Set attribute list name.
         MVC   DA34NAME,ALNNAME
* Set DAIRACB address.
         ST    R1,DA34ADDR
* Clear DAIRACB block before setting fields.
         XC    0(DAIRACB_LEN,R1),0(R1)
* Set RECFM=VB (variable blocked).
         MVI   DAIRECFM,X'48'
* Set LRECL=255.
         LHI   R7,255
         STH   R7,DAILRECL
* Call IKJDAIR to register attribute list.
         LA    R1,DAPLAREA
         L     R15,=V(IKJDAIR)
         BALR  R14,R15
* Change note: restore WORKAREA base after IKJDAIR.
* Problem: IKJDAIR may clobber R9 and R11.
* Expected effect: WORKAREA/TSODALO bases are reestablished.
* Impact: DAIR output fields are read safely.
* Ref: src/tsodalo.asm.md#dair-outdd-only
         LARL  R11,TSODALO
         USING TSODALO,R11
         L     R9,WORKPTR
         USING WORKAREA,R9
* Change note: store DAIR R15 into the workarea.
* Problem: writing to caller pointers after IKJDAIR can abend.
* Expected effect: C reads DAIR outputs directly from workarea.
* Impact: avoids 0C4 while preserving DAIR diagnostics in DAPB.
* Ref: src/tsodalo.asm.md#dair-attr-list
* Store DAIR R15 for X'34' in the workarea.
         ST    R15,R1534
* Re-establish DAPB34 addressability after call.
         LA    R14,DAPB34AREA
         USING DAPB34,R14
* Change note: use DAIR R15 return code for error handling.
* Problem: relying on DARC alone can miss DAIR RC=4/8 failures.
* Expected effect: DAIR errors propagate to the caller correctly.
* Impact: failures are detected before attempting STACK output.
* Ref: src/tsodalo.asm.md#dair-rc-r15
* Test DAIR RC for success.
         CHI   R15,0
         BNE   TDALO_FAIL34
* Store DAPB08 pointer in DAPL.
         ST    R6,DAPLDAPB
* Clear DAPB08 request block.
         XC    0(DAPB08_LEN,R6),0(R6)
* Set DAIR entry code X'08'.
         MVC   DA08CD,=X'0008'
* Load DSNAME buffer address.
         LA    R7,DSNBUF
* Store DSNAME pointer.
         ST    R7,DA08PDSN
* Change note: request DAIR-generated DDNAME when specific name
* is not required.
* Problem: fixed DDNAME can collide; DAIR then reassigns DDNAME.
* Expected effect: DAIR fills DA08DDN with the allocated DDNAME.
* Impact: C caller receives actual DDNAME for STACK/fopen.
* Ref: src/tsodalo.asm.md#dair-return-ddname
* Blank DDNAME to request DAIR-generated name.
         MVC   DA08DDN,BLANK8
* Change note: blank optional character fields when omitted.
* Problem: DA08UNIT/DA08SER/DA08MNM/DA08PSWD require blanks when
* omitted; zeroes can make DAIR reject the parameter list.
* Expected effect: DAIR treats optional fields as omitted.
* Impact: X'08' no longer returns RC=4 for invalid parameters.
* Ref: src/tsodalo.asm.md#dair-blank-fields
* Blank UNIT field (omitted).
         MVC   DA08UNIT,BLANK8
* Blank SERIAL field (omitted).
         MVC   DA08SER,BLANK8
* Blank MEMBER field (omitted).
         MVC   DA08MNM,BLANK8
* Blank PASSWORD field (omitted).
         MVC   DA08PSWD,BLANK8
* Change note: use attribute list name for DAIR DCB attributes.
* Problem: STACK OUTDD could not open output with SYSOUT DCB copy.
* Expected effect: DAIR uses explicit DCB parameters via attribute
* list.
* Impact: temporary OUTDD uses stable DCB for STACK output.
* Ref: src/tsodalo.asm.md#dair-attr-list
* Supply DCB attributes from attribute list.
         MVC   DA08ALN,ALNNAME
* Request NEW allocation.
         MVI   DA08DSP1,DA08NEW
* Delete on unallocate (private DD).
         MVI   DA08DPS2,DA08DEL
* Change note: set DAIR space quantities in binary.
* Problem: DA08PQTY/DA08SQTY require high-order byte zero and binary
* quantity; EBCDIC digits violate the format and cause RC=4.
* Expected effect: DAIR accepts the X'08' parameter list.
* Impact: OUTDD allocation no longer fails with parameter list invalid.
* Ref: src/tsodalo.asm.md#dair-space-qty
* Set primary space quantity (binary).
         MVC   DA08PQTY,SPACE1
* Set secondary space quantity (binary).
         MVC   DA08SQTY,SPACE1
* Use track units for space.
         MVI   DA08CTL,DA08TRKS
* Enable attribute list usage.
         OI    DA08CTL,DA08ATRL
* Load DAPL address into R1.
         LA    R1,DAPLAREA
* Load IKJDAIR entry point.
         L     R15,=V(IKJDAIR)
* Call IKJDAIR for private DD.
         BALR  R14,R15
* Change note: restore WORKAREA base after IKJDAIR.
* Problem: IKJDAIR may clobber R9 and R11.
* Expected effect: WORKAREA/TSODALO bases are reestablished.
* Impact: DAIR output fields are read safely.
* Ref: src/tsodalo.asm.md#dair-outdd-only
         LARL  R11,TSODALO
         USING TSODALO,R11
         L     R9,WORKPTR
         USING WORKAREA,R9
* Store DAIR R15 for X'08' in the workarea.
         ST    R15,R1508
* Test DAIR RC for success.
         LTR   R15,R15
* Branch if allocation failed.
         BNZ   TDALO_FAILRC
* Set return code to 0.
         XR    R15,R15
* Branch to epilog.
         B     TDALO_DONE
* Return with DAIR RC for allocation failure.
TDALO_FAILRC B TDALO_DONE      Branch to epilog.
* Return with DAIR RC for attribute list failure.
TDALO_FAIL34 B TDALO_DONE      Branch to epilog.
* Set RC=12 for NULL CPPL pointer.
TDALO_FAIL_CPPL L R15,=F'12'
         B     TDALO_DONE      Branch to epilog.
* Set RC=13 for NULL DDNAME pointer.
TDALO_FAIL_DDNAME L R15,=F'13'
         B     TDALO_DONE      Branch to epilog.
* Set RC=16 for NULL work pointer.
TDALO_FAIL_WORK L R15,=F'16'
* Return to caller with RC.
TDALO_DONE CEETERM RC=(R15)
* Emit literal pool for TSODALO.
         LTORG
* Drop TSODALO addressability.
         DROP  TSODALO
* Drop WORKAREA addressability.
         DROP  WORKAREA
* Drop DAPL addressability.
         DROP  DAPL
* Drop DAPB08 addressability.
         DROP  DAPB08
* Drop DAPB34 addressability.
         DROP  DAPB34
* Drop DAIRACB addressability.
         DROP  DAIRACB
* Drop CPPL addressability.
         DROP  CPPL
* Drop CAA addressability.
         DROP  CEECAA
* Drop DSA addressability.
         DROP  CEEDSA
* -------------------------------------------------------------
* Entry point: TSODFLO (LE-conforming, OS linkage).
* - Purpose: free private DD allocation only.
* - Input: R1 -> OS plist with 5 entries (cppl, ddname, dair_rc,
*   cat_rc, work).
* - Output: R15 RC (0 success; 8 DAIR failure; 12 invalid inputs).
* -------------------------------------------------------------
* Enter LE with OS plist.
TSODFLO  CEEENTRY PPA=TSDPPA2,MAIN=NO,PLIST=OS,PARMREG=1,BASE=(11),    X
               AMODE=31,RMODE=ANY
* Algorithm: validate plist entries and map required control blocks.
* - Validate cppl, ddname, rc pointers, and work pointer.
* - Map WORKAREA, DAPL, DAPB18, CPPL.
* Establish CSECT base register.
         USING TSODFLO,R11
* Enable CAA addressability.
         USING CEECAA,R12
* Enable DSA addressability.
         USING CEEDSA,R13
* Preserve caller plist pointer.
         LR    R8,R1
* Load CPPL pointer value.
         L     R2,0(R8)
* Validate CPPL pointer.
         LTR   R2,R2
* Branch if CPPL is NULL.
         BZ    TDFLO_FAIL
* Load DDNAME pointer value.
         L     R3,4(R8)
* Validate DDNAME pointer.
         LTR   R3,R3
* Branch if DDNAME is NULL.
         BZ    TDFLO_FAIL
* Load DAIR RC pointer value.
         L     R4,8(R8)
* Validate DAIR RC pointer.
         LTR   R4,R4
* Branch if DAIR RC pointer is NULL.
         BZ    TDFLO_FAIL
* Load CAT RC pointer value.
         L     R5,12(R8)
* Validate CAT RC pointer.
         LTR   R5,R5
* Branch if CAT RC pointer is NULL.
         BZ    TDFLO_FAIL
* Load work pointer value.
         L     R6,16(R8)
* Clear end-of-plist high bit.
         NILF  R6,X'7FFFFFFF'  Clear HOB via NILF.
* Check work pointer for NULL.
         LTR   R6,R6
* Branch if no work area.
         BZ    TDFLO_FAIL
* Use caller work area base.
         LR    R9,R6
* Map work area for fields.
         USING WORKAREA,R9
* Load DAPL base address.
         LA    R8,DAPLAREA
* Map DAPL fields with base.
         USING DAPL,R8
* Load DAPB18 base address.
         LA    R6,DAPB18AREA
* Map DAPB18 fields with base.
         USING DAPB18,R6
* Algorithm: free private DD allocation (DAPB18).
* Clear work area to defaults (split to stay within XC length limits).
         XC    0(WORKSZ1,R9),0(R9)
         XC    WORKSZ1(WORKSZ2,R9),WORKSZ1(R9)
* Copy caller DDNAME (8 chars).
         MVC   DDNAME(8),0(R3)
* Copy CPPL pointer to base.
         LR    R10,R2
* Map CPPL control block.
         USING CPPL,R10
* Load UPT pointer from CPPL.
         L     R7,CPPLUPT
* Store UPT pointer in DAPL.
         ST    R7,DAPLUPT
* Load ECT pointer from CPPL.
         L     R7,CPPLECT
* Store ECT pointer in DAPL.
         ST    R7,DAPLECT
* Change note: provide a valid ECB pointer in DAPL for DAIR calls.
* Problem: DAPLECB left zero can make DAIR reject the parameter list.
* Expected effect: DAIR accepts the DAPL and proceeds with
* deallocation.
* Impact: X'18' no longer risks RC=4 for invalid parameters.
* Ref: src/tsodalo.asm.md#dair-daplecb
* Load ECB storage address from WORKAREA.
         LA    R7,ECBWORD
* Store ECB pointer in DAPL.
         ST    R7,DAPLECB
* Load PSCB pointer from CPPL.
         L     R7,CPPLPSCB
* Store PSCB pointer in DAPL.
         ST    R7,DAPLPSCB
* Store DAPB pointer in DAPL.
         ST    R6,DAPLDAPB
* Clear DAPB18 request block.
         XC    0(DAPB18_LEN,R6),0(R6)
* Set DAIR entry code X'18'.
         MVC   DA18CD,=X'0018'
* Set DDNAME to private DD.
         MVC   DA18DDN,DDNAME
* Delete on unallocate (private DD).
         MVI   DA18DPS2,DA18DEL
* Load DAPL address into R1.
         LA    R1,DAPLAREA
* Load IKJDAIR entry point.
         L     R15,=V(IKJDAIR)
* Call IKJDAIR for private DD free.
         BALR  R14,R15
* Change note: store DAIR R15 into the workarea.
* Problem: DAIR return code was not visible to the C caller.
* Expected effect: C can log DAIR RC from X'18' free.
* Impact: free diagnostics report DAIR return code accurately.
* Ref: src/tsodalo.asm.md#dair-rc-r15
* Store DAIR R15 for X'18' in the workarea.
         ST    R15,R1518
* Load DAIR return code.
         LH    R7,DA18DARC
* Store DAIR RC for caller.
         ST    R7,0(R4)
* Load catalog return code.
         LH    R0,DA18CTRC
* Store catalog RC for caller.
         ST    R0,0(R5)
* Test DAIR RC for success.
         LTR   R15,R15
         BNZ   TDFLO_FAILRC    Branch if free failed.
* Set return code to 0.
         XR    R15,R15
         B     TDFLO_DONE      Branch to epilog.
* Return with DAIR RC for free failure.
TDFLO_FAILRC B TDFLO_DONE      Branch to epilog.
* Set RC=12 for invalid input.
TDFLO_FAIL L   R15,=F'12'
* Return to caller with RC.
TDFLO_DONE CEETERM RC=(R15)
* Emit literal pool for TSODFLO.
         LTORG
* Drop TSODFLO addressability.
         DROP  TSODFLO
* Drop WORKAREA addressability.
         DROP  WORKAREA
* Drop DAPL addressability.
         DROP  DAPL
* Drop DAPB18 addressability.
         DROP  DAPB18
* Drop CPPL addressability.
         DROP  CPPL
* Drop CAA addressability.
         DROP  CEECAA
* Drop DSA addressability.
         DROP  CEEDSA
* -------------------------------------------------------------
* Common data areas and DSECT mappings.
* -------------------------------------------------------------
* IBM doc reference for multi-entry PPA layout.
* Ref: src/tsodalo.asm.md#ceeppa-multi-entry
* Define LE PPA block for TSODALO (primary entry).
TSDPPA1  CEEPPA EPNAME=TSODALO,PEP=YES,PPA2=YES
* Define LE PPA block for TSODFLO (secondary entry).
TSDPPA2  CEEPPA EPNAME=TSODFLO,PEP=NO,PPA2=NO
* Blank fill for DSNAME.
BLANKS   DC    44C' '
* Blank fill for DDNAME return.
BLANK8   DC    CL8' '
* DSNAME prefix for temp dataset ("&"), ampersand via hex to avoid
* macro variable substitution.
DSNPFX   DC    X'50'
* Attribute list name for DAIR DCB parameters.
ALNNAME  DC    CL8'LUZALST'
* Fixed utility DSNAME suffix (7 chars after &).
DSNALT   DC    CL7'LUAZ000'
* Default space quantity (binary 1).
SPACE1   DC    F'1'
* Saved WORKAREA base for DAIR calls.
WORKPTR  DS    F
* Define LE CAA DSECT anchor.
CEECAA   DSECT
* Map CAA fields via macro.
         CEECAA
* Define LE DSA DSECT anchor.
CEEDSA   DSECT
* Map DSA fields via macro.
         CEEDSA
* Define DAPL DSECT anchor.
DAPL     DSECT
* Map DAPL fields via macro.
         IKJDAPL
DAPL_LEN EQU   *-DAPL          Compute DAPL size.
* Define DAPB08 DSECT anchor.
DAPB08   DSECT
* Map DAPB08 fields via macro.
         IKJDAP08
DAPB08_LEN EQU *-DAPB08        Compute DAPB08 size.
* Define DAPB18 DSECT anchor.
DAPB18   DSECT
* Map DAPB18 fields via macro.
         IKJDAP18
DAPB18_LEN EQU *-DAPB18        Compute DAPB18 size.
* Define DAPB34 DSECT anchor.
DAPB34   DSECT
* Map DAPB34 fields via macro.
         IKJDAP34
DAPB34_LEN EQU *-DAPB34        Compute DAPB34 size.
* Define DAIRACB DSECT anchor.
DAIRACB  DSECT
* Map DAIRACB fields via macro.
         IKJDACB
DAIRACB_LEN EQU *-DAIRACB      Compute DAIRACB size.
* Start work area DSECT.
WORKAREA DSECT
* Allocate DAPL storage.
DAPLAREA DS    CL(DAPL_LEN)
* Allocate DAPB08 storage.
DAPB08AREA DS  CL(DAPB08_LEN)
* Allocate DAPB18 storage.
DAPB18AREA DS  CL(DAPB18_LEN)
* Allocate DAPB34 storage.
DAPB34AREA DS  CL(DAPB34_LEN)
* Allocate DAIRACB storage.
DAIRACBAREA DS CL(DAIRACB_LEN)
* DSNAME length + 44-byte name.
DSNBUF   DS    H,CL44
* Saved DDNAME buffer.
DDNAME   DS    CL8
* Align to fullword boundary for R15 storage.
         DS    0F
* Saved DAIR R15 for X'34' (attribute list).
R1534    DS    F
* Saved DAIR R15 for X'08' (allocation).
R1508    DS    F
* Saved DAIR R15 for X'18' (free).
R1518    DS    F
* Caller ECB storage for DAIR (zeroed with work area).
ECBWORD  DS    F
* Compute work area size.
WORKSIZE EQU   *-WORKAREA
* Split sizes for XC length limit (<=256 bytes).
WORKSZ1  EQU   128
WORKSZ2  EQU   WORKSIZE-WORKSZ1
* Define CPPL anchor DSECT.
CPPL     DSECT
* Map CPPL fields via macro.
         IKJCPPL
         END   TSODALO         End of module source.
