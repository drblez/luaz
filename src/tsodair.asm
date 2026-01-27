* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
*
* DAIR ASM wrappers for temporary DD allocation and SYSTSPRT
* redirection.
*
* Object Table:
* | Object  | Kind  | Purpose |
* |---------|-------|---------|
* | TSODALC | CSECT | Allocate private DD and redirect SYSTSPRT |
* | TSODFRE | CSECT | Free SYSTSPRT and private DD allocation |
*
* User Actions:
* - Run under TMP (IKJEFT01) so DAIR is available and SYSTSPRT is
* active.
* - Ensure IKJDAIR is available in the current TSO/E environment.
*
* Platform Requirements:
* - LE: required (CEEENTRY/CEETERM).
* - AMODE: 31-bit (TMP/TSO services).
* - EBCDIC: DDNAME/DSNAME fields are EBCDIC.
* - DDNAME I/O: uses SYSTSPRT redirection for command output.
*
* Emit assembler listing for debug.
         PRINT GEN
* Declare IKJDAIR external entry.
         EXTRN IKJDAIR
* Change note: move AMODE/RMODE into CEEENTRY and align with
* LE_C_HLASM_RULES.
* Problem: standalone AMODE/RMODE conflicts with CEEENTRY expansion
* (ASMA186E) and HOB literals.
* Expected effect: ASMA90 RC=0 with stable base addressability and
* correct pointer handling.
* Impact: DAIR wrappers use CEEENTRY base and NILF for HOB.
* Ref: src/tsodair.md#ceeentry-amode-rmode
* -------------------------------------------------------------
* Entry point: TSODALC (LE-conforming, OS linkage).
* - Purpose: allocate private DD and redirect SYSTSPRT to same DSN.
* - Input: R1 -> OS plist with 5 entries (cppl, ddname, dair_rc,
* cat_rc, work).
* - Output: R15 RC (0 success; 8 DAIR failure; 12-16 invalid inputs).
* - Notes: ddname points to 8-byte EBCDIC DDNAME; work size >=
* WORKSIZE.
* -------------------------------------------------------------
* Define TSODALC control section.
TSODALC  CSECT
* Enter LE with OS plist (AMODE/RMODE set via CEEENTRY).
TSODALC  CEEENTRY PPA=TSDPPA1,MAIN=NO,PLIST=OS,PARMREG=1,BASE=(11),    X
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
* - Validate cppl, ddname, rc pointers, and work pointer.
* - Map WORKAREA, DAPL, DAPB08, CPPL.
* Establish CSECT base register from CEEENTRY.
         USING TSODALC,R11
* Enable CAA addressability.
         USING CEECAA,R12
* Enable DSA addressability.
         USING CEEDSA,R13
* Preserve caller plist pointer.
         LR    R8,R1
         L     R2,0(R8)             Load CPPL pointer value.
         LTR   R2,R2                Validate CPPL pointer.
* Branch if CPPL pointer is NULL.
         BZ    TDALC_FAIL_CPPL
* Load DDNAME pointer value.
         L     R3,4(R8)
* Validate DDNAME pointer.
         LTR   R3,R3
* Branch if DDNAME pointer is NULL.
         BZ    TDALC_FAIL_DDNAME
* Load DAIR RC pointer value.
         L     R4,8(R8)
* Validate DAIR RC pointer.
         LTR   R4,R4
* Branch if DAIR RC pointer is NULL.
         BZ    TDALC_FAIL_DAIRRC
* Load CAT RC pointer value.
         L     R5,12(R8)
* Validate CAT RC pointer.
         LTR   R5,R5
* Branch if CAT RC pointer is NULL.
         BZ    TDALC_FAIL_CATRC
         L     R6,16(R8)            Load work pointer value.
* Clear end-of-plist high bit on work pointer.
         NILF  R6,X'7FFFFFFF'       Clear HOB via NILF.
* Check work pointer for NULL.
         LTR   R6,R6
* Branch if work area pointer is NULL.
         BZ    TDALC_FAIL_WORK
* Use caller work area base.
         LR    R9,R6
* Map work area for fields.
         USING WORKAREA,R9
         LA    R8,DAPLAREA          Load DAPL base address.
* Map DAPL fields with base.
         USING DAPL,R8
* Load DAPB08 base address.
         LA    R6,DAPB08AREA
* Map DAPB08 fields with base.
         USING DAPB08,R6
* Algorithm: build DAPL/DAPB08 for private DD allocation.
* - Construct DSNAME &&LZ<DDNAME>, set attributes from SYSTSPRT.
* Clear work area to defaults.
         XC    0(WORKSIZE,R9),0(R9)
* Copy caller DDNAME (8 chars).
         MVC   DDNAME(8),0(R3)
         MVC   DSNBUF+2(44),BLANKS  Blank-fill DSNAME area.
* Set DSNAME prefix "&&LZ".
         MVC   DSNBUF+2(4),DSNPFX
* Append DDNAME to DSNAME.
         MVC   DSNBUF+6(8),DDNAME
* Load DSNAME length (12).
         LA    R7,12
         STH   R7,DSNBUF            Store DSNAME length.
* Copy CPPL pointer to base.
         LR    R10,R2
         USING CPPL,R10             Map CPPL control block.
* Load UPT pointer from CPPL.
         L     R7,CPPLUPT
* Store UPT pointer in DAPL.
         ST    R7,DAPLUPT
* Load ECT pointer from CPPL.
         L     R7,CPPLECT
* Store ECT pointer in DAPL.
         ST    R7,DAPLECT
* Load PSCB pointer from CPPL.
         L     R7,CPPLPSCB
* Store PSCB pointer in DAPL.
         ST    R7,DAPLPSCB
* Store DAPB pointer in DAPL.
         ST    R6,DAPLDAPB
* Clear DAPB08 request block.
         XC    0(DAPB08_LEN,R6),0(R6)
* Set DAIR entry code X'08'.
         MVC   DA08CD,=X'0008'
* Load DSNAME buffer address.
         LA    R7,DSNBUF
         ST    R7,DA08PDSN          Store DSNAME pointer.
* Set DDNAME for private output.
         MVC   DA08DDN,DDNAME
* Copy DCB attributes from SYSTSPRT.
         MVC   DA08ALN,SYSALN
         MVI   DA08DSP1,DA08NEW     Request NEW allocation.
* Delete on unallocate (private DD).
         MVI   DA08DPS2,DA08DEL
* Set primary space quantity.
         MVC   DA08PQTY,SPACE1
* Set secondary space quantity.
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
         LH    R7,DA08DARC          Load DAIR return code.
* Store DAIR RC for caller.
         ST    R7,0(R4)
* Load catalog return code.
         LH    R0,DA08CTRC
* Store catalog RC for caller.
         ST    R0,0(R5)
* Test DAIR RC for success.
         CHI   R7,0
* Branch if allocation failed.
         BNE   TDALC_FAILRC
* Algorithm: redirect SYSTSPRT to private DD.
* - Reuse DAPB08 to allocate SYSTSPRT pointing to private DD DSN.
         MVC   DA08DDN,SYSDDN       Set DDNAME to SYSTSPRT.
* Keep on unallocate (SYSTSPRT).
         MVI   DA08DPS2,DA08KEEP
* Load DAPL address into R1.
         LA    R1,DAPLAREA
* Load IKJDAIR entry point.
         L     R15,=V(IKJDAIR)
* Call IKJDAIR for SYSTSPRT.
         BALR  R14,R15
         LH    R7,DA08DARC          Load DAIR return code.
* Store DAIR RC for caller.
         ST    R7,0(R4)
* Load catalog return code.
         LH    R0,DA08CTRC
* Store catalog RC for caller.
         ST    R0,0(R5)
* Test DAIR RC for success.
         CHI   R7,0
* Branch if SYSTSPRT alloc failed.
         BNE   TDALC_FAILSPR
         XR    R15,R15              Set return code to 0.
         B     TDALC_DONE           Branch to epilog.
* Set nonzero return code.
TDALC_FAILRC L R15,=F'8'
         B     TDALC_DONE           Branch to epilog.
* Algorithm: on SYSTSPRT allocation failure, free private DD (DAPB18).
* Load DAPB18 base address.
TDALC_FAILSPR LA R6,DAPB18AREA
* Map DAPB18 fields with base.
         USING DAPB18,R6
* Clear DAPB18 request block.
         XC    0(DAPB18_LEN,R6),0(R6)
* Set DAIR entry code X'18'.
         MVC   DA18CD,=X'0018'
* Set DDNAME to private DD.
         MVC   DA18DDN,DDNAME
* Delete on unallocate (private DD).
         MVI   DA18DPS2,DA18DEL
* Store DAPB pointer in DAPL.
         ST    R6,DAPLDAPB
* Load DAPL address into R1.
         LA    R1,DAPLAREA
* Load IKJDAIR entry point.
         L     R15,=V(IKJDAIR)
* Call IKJDAIR to free private DD.
         BALR  R14,R15
* Set nonzero return code.
         L     R15,=F'8'
         B     TDALC_DONE           Branch to epilog.
* Set RC=12 for NULL CPPL pointer.
TDALC_FAIL_CPPL L R15,=F'12'
         B     TDALC_DONE           Branch to epilog.
* Set RC=13 for NULL DDNAME pointer.
TDALC_FAIL_DDNAME L R15,=F'13'
         B     TDALC_DONE           Branch to epilog.
* Set RC=14 for NULL DAIR RC pointer.
TDALC_FAIL_DAIRRC L R15,=F'14'
         B     TDALC_DONE           Branch to epilog.
* Set RC=15 for NULL CAT RC pointer.
TDALC_FAIL_CATRC L R15,=F'15'
         B     TDALC_DONE           Branch to epilog.
* Set RC=16 for NULL work area pointer.
TDALC_FAIL_WORK L R15,=F'16'
* Return to caller with RC.
TDALC_DONE CEETERM RC=(R15)
* Emit literal pool for TSODALC.
         LTORG
* Drop TSODALC addressability before the next entry point.
         DROP  TSODALC
* Drop WORKAREA addressability.
         DROP  WORKAREA
* Drop DAPL addressability.
         DROP  DAPL
* Change note: do not DROP DAPB08 when no active USING.
* Problem: ASMA307E when DAPB08 is inactive after LTORG.
* Expected effect: no ASMA307E; runtime behavior unchanged.
* Impact: DAPB08 is already inactive by the time of drops.
* Drop DAPB18 addressability.
         DROP  DAPB18
* Drop CPPL addressability.
         DROP  CPPL
* Drop CAA addressability.
         DROP  CEECAA
* Drop DSA addressability.
         DROP  CEEDSA
* -------------------------------------------------------------
* Entry point: TSODFRE (LE-conforming, OS linkage).
* - Purpose: free SYSTSPRT and the private DD allocation.
* - Input: R1 -> OS plist with 5 entries (cppl, ddname, dair_rc,
* cat_rc, work).
* - Output: R15 RC (0 success; 8 DAIR failure; 12 invalid inputs).
* -------------------------------------------------------------
* Enter LE with OS plist.
TSODFRE  CEEENTRY PPA=TSDPPA2,MAIN=NO,PLIST=OS,PARMREG=1,BASE=(11),    X
               AMODE=31,RMODE=ANY
* Algorithm: validate plist entries and map required control blocks.
* - Validate cppl, ddname, rc pointers, and work pointer.
* - Map WORKAREA, DAPL, DAPB18, CPPL.
* Establish CSECT base register.
         USING TSODFRE,R11
* Enable CAA addressability.
         USING CEECAA,R12
* Enable DSA addressability.
         USING CEEDSA,R13
* Preserve caller plist pointer.
         LR    R8,R1
         L     R2,0(R8)             Load CPPL pointer value.
         LTR   R2,R2                Validate CPPL pointer.
         BZ    TDFRE_FAIL           Branch if CPPL is NULL.
* Load DDNAME pointer value.
         L     R3,4(R8)
* Validate DDNAME pointer.
         LTR   R3,R3
* Branch if DDNAME is NULL.
         BZ    TDFRE_FAIL
* Load DAIR RC pointer value.
         L     R4,8(R8)
* Validate DAIR RC pointer.
         LTR   R4,R4
* Branch if DAIR RC pointer is NULL.
         BZ    TDFRE_FAIL
* Load CAT RC pointer value.
         L     R5,12(R8)
* Validate CAT RC pointer.
         LTR   R5,R5
* Branch if CAT RC pointer is NULL.
         BZ    TDFRE_FAIL
         L     R6,16(R8)            Load work pointer value.
* Clear end-of-plist high bit.
         NILF  R6,X'7FFFFFFF'       Clear HOB via NILF.
* Check work pointer for NULL.
         LTR   R6,R6
         BZ    TDFRE_FAIL           Branch if no work area.
* Use caller work area base.
         LR    R9,R6
* Map work area for fields.
         USING WORKAREA,R9
         LA    R8,DAPLAREA          Load DAPL base address.
* Map DAPL fields with base.
         USING DAPL,R8
* Load DAPB18 base address.
         LA    R6,DAPB18AREA
* Map DAPB18 fields with base.
         USING DAPB18,R6
* Algorithm: free SYSTSPRT allocation (DAPB18).
* Clear work area to defaults.
         XC    0(WORKSIZE,R9),0(R9)
* Copy caller DDNAME (8 chars).
         MVC   DDNAME(8),0(R3)
* Copy CPPL pointer to base.
         LR    R10,R2
         USING CPPL,R10             Map CPPL control block.
* Load UPT pointer from CPPL.
         L     R7,CPPLUPT
* Store UPT pointer in DAPL.
         ST    R7,DAPLUPT
* Load ECT pointer from CPPL.
         L     R7,CPPLECT
* Store ECT pointer in DAPL.
         ST    R7,DAPLECT
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
         MVC   DA18DDN,SYSDDN       Set DDNAME to SYSTSPRT.
* Keep on unallocate (SYSTSPRT).
         MVI   DA18DPS2,DA18KEEP
* Load DAPL address into R1.
         LA    R1,DAPLAREA
* Load IKJDAIR entry point.
         L     R15,=V(IKJDAIR)
* Call IKJDAIR for SYSTSPRT free.
         BALR  R14,R15
         LH    R7,DA18DARC          Load DAIR return code.
* Store DAIR RC for caller.
         ST    R7,0(R4)
* Load catalog return code.
         LH    R0,DA18CTRC
* Store catalog RC for caller.
         ST    R0,0(R5)
* Test DAIR RC for success.
         CHI   R7,0
         BNE   TDFRE_FAILRC         Branch if free failed.
* Algorithm: free private DD allocation (DAPB18).
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
         LH    R7,DA18DARC          Load DAIR return code.
* Store DAIR RC for caller.
         ST    R7,0(R4)
* Load catalog return code.
         LH    R0,DA18CTRC
* Store catalog RC for caller.
         ST    R0,0(R5)
* Test DAIR RC for success.
         CHI   R7,0
         BNE   TDFRE_FAILRC         Branch if free failed.
         XR    R15,R15              Set return code to 0.
         B     TDFRE_DONE           Branch to epilog.
* Set nonzero return code.
TDFRE_FAILRC L R15,=F'8'
         B     TDFRE_DONE           Branch to epilog.
* Set RC=12 for invalid input.
TDFRE_FAIL L   R15,=F'12'
* Return to caller with RC.
TDFRE_DONE CEETERM RC=(R15)
* Emit literal pool for TSODFRE.
         LTORG
* Drop TSODFRE addressability.
         DROP  TSODFRE
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
* Ref: src/tsodair.md#ceeppa-multi-entry
* Define LE PPA block for TSODALC (primary entry).
TSDPPA1  CEEPPA EPNAME=TSODALC,PEP=YES,PPA2=YES
* Define LE PPA block for TSODFRE (secondary entry).
TSDPPA2  CEEPPA EPNAME=TSODFRE,PEP=NO,PPA2=NO
BLANKS   DC    44C' '               Blank fill for DSNAME.
* DSNAME prefix for temp dataset.
DSNPFX   DC    CL4'&&LZ'
SYSALN   DC    CL8'SYSTSPRT'        DCB source DDNAME.
* SYSTSPRT DDNAME constant.
SYSDDN   DC    CL8'SYSTSPRT'
SPACE1   DC    CL4'0001'            Default space quantity.
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
DAPL_LEN EQU   *-DAPL               Compute DAPL size.
* Define DAPB08 DSECT anchor.
DAPB08   DSECT
* Map DAPB08 fields via macro.
         IKJDAP08
DAPB08_LEN EQU *-DAPB08             Compute DAPB08 size.
* Define DAPB18 DSECT anchor.
DAPB18   DSECT
* Map DAPB18 fields via macro.
         IKJDAP18
DAPB18_LEN EQU *-DAPB18             Compute DAPB18 size.
WORKAREA DSECT Start                work area DSECT.
DAPLAREA   DS  CL(DAPL_LEN)         Allocate DAPL storage.
DAPB08AREA DS  CL(DAPB08_LEN)       Allocate DAPB08 storage.
DAPB18AREA DS  CL(DAPB18_LEN)       Allocate DAPB18 storage.
* DSNAME length + 44-byte name.
DSNBUF   DS    H,CL44
DDNAME   DS    CL8                  Saved DDNAME buffer.
WORKSIZE EQU   *-WORKAREA           Compute work area size.
* Define CPPL anchor DSECT.
CPPL     DSECT
* Map CPPL fields via macro.
         IKJCPPL
         END   TSODALC              End of module source.
