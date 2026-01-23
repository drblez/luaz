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
         PRINT GEN                              Emit assembler listing for debug.
         EXTRN IKJDAIR                          Declare IKJDAIR external entry.
* -------------------------------------------------------------
* Entry point: TSODALC (LE-conforming, OS linkage).
* - Purpose: allocate private DD and redirect SYSTSPRT to same DSN.
* - Input: R1 -> OS plist with 5 entries (cppl, ddname, dair_rc, cat_rc, work).
* - Output: R15 RC (0 success; 8 DAIR failure; 12-16 invalid inputs).
* - Notes: ddname points to 8-byte EBCDIC DDNAME; work size >= WORKSIZE.
* -------------------------------------------------------------
TSODALC  CEEENTRY PPA=TSDPPA1,MAIN=NO,PLIST=OS,PARMREG=1  Enter LE with OS plist.
R0       EQU   0                               Define register 0 alias.
R1       EQU   1                               Define register 1 alias.
R2       EQU   2                               Define register 2 alias.
R3       EQU   3                               Define register 3 alias.
R4       EQU   4                               Define register 4 alias.
R5       EQU   5                               Define register 5 alias.
R6       EQU   6                               Define register 6 alias.
R7       EQU   7                               Define register 7 alias.
R8       EQU   8                               Define register 8 alias.
R9       EQU   9                               Define register 9 alias.
R10      EQU   10                              Define register 10 alias.
R11      EQU   11                              Define register 11 alias.
R12      EQU   12                              Define register 12 alias.
R13      EQU   13                              Define register 13 alias.
R14      EQU   14                              Define register 14 alias.
R15      EQU   15                              Define register 15 alias.
* Algorithm: validate plist entries and map required control blocks.
* - Validate cppl, ddname, rc pointers, and work pointer.
* - Map WORKAREA, DAPL, DAPB08, CPPL.
         LARL  R11,TSODALC                     Load CSECT base for TSODALC.
         USING TSODALC,R11                     Establish CSECT base register.
         USING CEECAA,R12                      Enable CAA addressability.
         USING CEEDSA,R13                      Enable DSA addressability.
         LR    R8,R1                           Preserve caller plist pointer.
         L     R2,0(R8)                        Load CPPL slot address.
         L     R2,0(R2)                        Load CPPL pointer value.
         LTR   R2,R2                           Validate CPPL pointer.
         BZ    TDALC_FAIL_CPPL                 Branch if CPPL pointer is NULL.
         L     R3,4(R8)                        Load DDNAME slot address.
         L     R3,0(R3)                        Load DDNAME pointer value.
         LTR   R3,R3                           Validate DDNAME pointer.
         BZ    TDALC_FAIL_DDNAME               Branch if DDNAME pointer is NULL.
         L     R4,8(R8)                        Load DAIR RC slot address.
         L     R4,0(R4)                        Load DAIR RC pointer value.
         LTR   R4,R4                           Validate DAIR RC pointer.
         BZ    TDALC_FAIL_DAIRRC               Branch if DAIR RC pointer is NULL.
         L     R5,12(R8)                       Load CAT RC slot address.
         L     R5,0(R5)                        Load CAT RC pointer value.
         LTR   R5,R5                           Validate CAT RC pointer.
         BZ    TDALC_FAIL_CATRC                Branch if CAT RC pointer is NULL.
         L     R6,16(R8)                       Load work slot address.
         N     R6,=X'7FFFFFFF'                 Clear end-of-plist high bit.
         L     R6,0(R6)                        Load work pointer value.
         LTR   R6,R6                           Check work pointer for NULL.
         BZ    TDALC_FAIL_WORK                 Branch if work area pointer is NULL.
         LR    R9,R6                           Use caller work area base.
         USING WORKAREA,R9                     Map work area for fields.
         LA    R8,DAPLAREA                     Load DAPL base address.
         USING DAPL,R8                         Map DAPL fields with base.
         LA    R6,DAPB08AREA                   Load DAPB08 base address.
         USING DAPB08,R6                       Map DAPB08 fields with base.
* Algorithm: build DAPL/DAPB08 for private DD allocation.
* - Construct DSNAME &&LZ<DDNAME>, set attributes from SYSTSPRT.
         XC    0(WORKSIZE,R9),0(R9)            Clear work area to defaults.
         MVC   DDNAME(8),0(R3)                 Copy caller DDNAME (8 chars).
         MVC   DSNBUF+2(44),BLANKS             Blank-fill DSNAME area.
         MVC   DSNBUF+2(4),DSNPFX              Set DSNAME prefix "&&LZ".
         MVC   DSNBUF+6(8),DDNAME              Append DDNAME to DSNAME.
         LA    R7,12                           Load DSNAME length (12).
         STH   R7,DSNBUF                       Store DSNAME length.
         LR    R10,R2                          Copy CPPL pointer to base.
         USING CPPL,R10                        Map CPPL control block.
         L     R7,CPPLUPT                      Load UPT pointer from CPPL.
         ST    R7,DAPLUPT                      Store UPT pointer in DAPL.
         L     R7,CPPLECT                      Load ECT pointer from CPPL.
         ST    R7,DAPLECT                      Store ECT pointer in DAPL.
         L     R7,CPPLPSCB                     Load PSCB pointer from CPPL.
         ST    R7,DAPLPSCB                     Store PSCB pointer in DAPL.
         ST    R6,DAPLDAPB                     Store DAPB pointer in DAPL.
         XC    0(DAPB08_LEN,R6),0(R6)          Clear DAPB08 request block.
         MVC   DA08CD,=X'0008'                 Set DAIR entry code X'08'.
         LA    R7,DSNBUF                       Load DSNAME buffer address.
         ST    R7,DA08PDSN                     Store DSNAME pointer.
         MVC   DA08DDN,DDNAME                  Set DDNAME for private output.
         MVC   DA08ALN,SYSALN                  Copy DCB attributes from SYSTSPRT.
         MVI   DA08DSP1,DA08NEW                Request NEW allocation.
         MVI   DA08DPS2,DA08DEL                Delete on unallocate (private DD).
         MVC   DA08PQTY,SPACE1                 Set primary space quantity.
         MVC   DA08SQTY,SPACE1                 Set secondary space quantity.
         MVI   DA08CTL,DA08TRKS                Use track units for space.
         OI    DA08CTL,DA08ATRL                Enable attribute list usage.
         LA    R1,DAPLAREA                     Load DAPL address into R1.
         L     R15,=V(IKJDAIR)                 Load IKJDAIR entry point.
         BALR  R14,R15                         Call IKJDAIR for private DD.
         LH    R7,DA08DARC                     Load DAIR return code.
         ST    R7,0(R4)                        Store DAIR RC for caller.
         LH    R0,DA08CTRC                     Load catalog return code.
         ST    R0,0(R5)                        Store catalog RC for caller.
         CHI   R7,0                            Test DAIR RC for success.
         BNE   TDALC_FAILRC                    Branch if allocation failed.
* Algorithm: redirect SYSTSPRT to private DD.
* - Reuse DAPB08 to allocate SYSTSPRT pointing to private DD DSN.
         MVC   DA08DDN,SYSDDN                  Set DDNAME to SYSTSPRT.
         MVI   DA08DPS2,DA08KEEP               Keep on unallocate (SYSTSPRT).
         LA    R1,DAPLAREA                     Load DAPL address into R1.
         L     R15,=V(IKJDAIR)                 Load IKJDAIR entry point.
         BALR  R14,R15                         Call IKJDAIR for SYSTSPRT.
         LH    R7,DA08DARC                     Load DAIR return code.
         ST    R7,0(R4)                        Store DAIR RC for caller.
         LH    R0,DA08CTRC                     Load catalog return code.
         ST    R0,0(R5)                        Store catalog RC for caller.
         CHI   R7,0                            Test DAIR RC for success.
         BNE   TDALC_FAILSPR                   Branch if SYSTSPRT alloc failed.
         XR    R15,R15                         Set return code to 0.
         B     TDALC_DONE                      Branch to epilog.
TDALC_FAILRC L  R15,=F'8'                      Set nonzero return code.
         B     TDALC_DONE                      Branch to epilog.
* Algorithm: on SYSTSPRT allocation failure, free private DD (DAPB18).
TDALC_FAILSPR LA  R6,DAPB18AREA                Load DAPB18 base address.
         USING DAPB18,R6                       Map DAPB18 fields with base.
         XC    0(DAPB18_LEN,R6),0(R6)          Clear DAPB18 request block.
         MVC   DA18CD,=X'0018'                 Set DAIR entry code X'18'.
         MVC   DA18DDN,DDNAME                  Set DDNAME to private DD.
         MVI   DA18DPS2,DA18DEL                Delete on unallocate (private DD).
         ST    R6,DAPLDAPB                     Store DAPB pointer in DAPL.
         LA    R1,DAPLAREA                     Load DAPL address into R1.
         L     R15,=V(IKJDAIR)                 Load IKJDAIR entry point.
         BALR  R14,R15                         Call IKJDAIR to free private DD.
         L     R15,=F'8'                       Set nonzero return code.
         B     TDALC_DONE                      Branch to epilog.
TDALC_FAIL_CPPL L  R15,=F'12'                  Set RC=12 for NULL CPPL pointer.
         B     TDALC_DONE                      Branch to epilog.
TDALC_FAIL_DDNAME L  R15,=F'13'                Set RC=13 for NULL DDNAME pointer.
         B     TDALC_DONE                      Branch to epilog.
TDALC_FAIL_DAIRRC L  R15,=F'14'                Set RC=14 for NULL DAIR RC pointer.
         B     TDALC_DONE                      Branch to epilog.
TDALC_FAIL_CATRC L  R15,=F'15'                 Set RC=15 for NULL CAT RC pointer.
         B     TDALC_DONE                      Branch to epilog.
TDALC_FAIL_WORK L  R15,=F'16'                  Set RC=16 for NULL work area pointer.
TDALC_DONE CEETERM RC=(R15)                    Return to caller with RC.
* -------------------------------------------------------------
* Entry point: TSODFRE (LE-conforming, OS linkage).
* - Purpose: free SYSTSPRT and the private DD allocation.
* - Input: R1 -> OS plist with 5 entries (cppl, ddname, dair_rc, cat_rc, work).
* - Output: R15 RC (0 success; 8 DAIR failure; 12 invalid inputs).
* -------------------------------------------------------------
TSODFRE  CEEENTRY PPA=TSDPPA2,MAIN=NO,PLIST=OS,PARMREG=1  Enter LE with OS plist.
* Algorithm: validate plist entries and map required control blocks.
* - Validate cppl, ddname, rc pointers, and work pointer.
* - Map WORKAREA, DAPL, DAPB18, CPPL.
         LARL  R11,TSODFRE                     Load CSECT base for TSODFRE.
         USING TSODFRE,R11                     Establish CSECT base register.
         USING CEECAA,R12                      Enable CAA addressability.
         USING CEEDSA,R13                      Enable DSA addressability.
         LR    R8,R1                           Preserve caller plist pointer.
         L     R2,0(R8)                        Load CPPL slot address.
         L     R2,0(R2)                        Load CPPL pointer value.
         LTR   R2,R2                           Validate CPPL pointer.
         BZ    TDFRE_FAIL                      Branch if CPPL is NULL.
         L     R3,4(R8)                        Load DDNAME slot address.
         L     R3,0(R3)                        Load DDNAME pointer value.
         LTR   R3,R3                           Validate DDNAME pointer.
         BZ    TDFRE_FAIL                      Branch if DDNAME is NULL.
         L     R4,8(R8)                        Load DAIR RC slot address.
         L     R4,0(R4)                        Load DAIR RC pointer value.
         LTR   R4,R4                           Validate DAIR RC pointer.
         BZ    TDFRE_FAIL                      Branch if DAIR RC pointer is NULL.
         L     R5,12(R8)                       Load CAT RC slot address.
         L     R5,0(R5)                        Load CAT RC pointer value.
         LTR   R5,R5                           Validate CAT RC pointer.
         BZ    TDFRE_FAIL                      Branch if CAT RC pointer is NULL.
         L     R6,16(R8)                       Load work slot address.
         N     R6,=X'7FFFFFFF'                 Clear end-of-plist high bit.
         L     R6,0(R6)                        Load work pointer value.
         LTR   R6,R6                           Check work pointer for NULL.
         BZ    TDFRE_FAIL                      Branch if no work area.
         LR    R9,R6                           Use caller work area base.
         USING WORKAREA,R9                     Map work area for fields.
         LA    R8,DAPLAREA                     Load DAPL base address.
         USING DAPL,R8                         Map DAPL fields with base.
         LA    R6,DAPB18AREA                   Load DAPB18 base address.
         USING DAPB18,R6                       Map DAPB18 fields with base.
* Algorithm: free SYSTSPRT allocation (DAPB18).
         XC    0(WORKSIZE,R9),0(R9)            Clear work area to defaults.
         MVC   DDNAME(8),0(R3)                 Copy caller DDNAME (8 chars).
         LR    R10,R2                          Copy CPPL pointer to base.
         USING CPPL,R10                        Map CPPL control block.
         L     R7,CPPLUPT                      Load UPT pointer from CPPL.
         ST    R7,DAPLUPT                      Store UPT pointer in DAPL.
         L     R7,CPPLECT                      Load ECT pointer from CPPL.
         ST    R7,DAPLECT                      Store ECT pointer in DAPL.
         L     R7,CPPLPSCB                     Load PSCB pointer from CPPL.
         ST    R7,DAPLPSCB                     Store PSCB pointer in DAPL.
         ST    R6,DAPLDAPB                     Store DAPB pointer in DAPL.
         XC    0(DAPB18_LEN,R6),0(R6)          Clear DAPB18 request block.
         MVC   DA18CD,=X'0018'                 Set DAIR entry code X'18'.
         MVC   DA18DDN,SYSDDN                  Set DDNAME to SYSTSPRT.
         MVI   DA18DPS2,DA18KEEP               Keep on unallocate (SYSTSPRT).
         LA    R1,DAPLAREA                     Load DAPL address into R1.
         L     R15,=V(IKJDAIR)                 Load IKJDAIR entry point.
         BALR  R14,R15                         Call IKJDAIR for SYSTSPRT free.
         LH    R7,DA18DARC                     Load DAIR return code.
         ST    R7,0(R4)                        Store DAIR RC for caller.
         LH    R0,DA18CTRC                     Load catalog return code.
         ST    R0,0(R5)                        Store catalog RC for caller.
         CHI   R7,0                            Test DAIR RC for success.
         BNE   TDFRE_FAILRC                    Branch if free failed.
* Algorithm: free private DD allocation (DAPB18).
         MVC   DA18DDN,DDNAME                  Set DDNAME to private DD.
         MVI   DA18DPS2,DA18DEL                Delete on unallocate (private DD).
         LA    R1,DAPLAREA                     Load DAPL address into R1.
         L     R15,=V(IKJDAIR)                 Load IKJDAIR entry point.
         BALR  R14,R15                         Call IKJDAIR for private DD free.
         LH    R7,DA18DARC                     Load DAIR return code.
         ST    R7,0(R4)                        Store DAIR RC for caller.
         LH    R0,DA18CTRC                     Load catalog return code.
         ST    R0,0(R5)                        Store catalog RC for caller.
         CHI   R7,0                            Test DAIR RC for success.
         BNE   TDFRE_FAILRC                    Branch if free failed.
         XR    R15,R15                         Set return code to 0.
         B     TDFRE_DONE                      Branch to epilog.
TDFRE_FAILRC L  R15,=F'8'                      Set nonzero return code.
         B     TDFRE_DONE                      Branch to epilog.
TDFRE_FAIL L  R15,=F'12'                       Set RC=12 for invalid input.
TDFRE_DONE CEETERM RC=(R15)                    Return to caller with RC.
* -------------------------------------------------------------
* Common data areas and DSECT mappings.
* -------------------------------------------------------------
TSDPPA1  CEEPPA                               Define LE PPA block for TSODALC.
TSDPPA2  CEEPPA                               Define LE PPA block for TSODFRE.
BLANKS  DC    44C' '                          Blank fill for DSNAME.
DSNPFX  DC    CL4'&&LZ'                       DSNAME prefix for temp dataset.
SYSALN  DC    CL8'SYSTSPRT'                   DCB source DDNAME.
SYSDDN  DC    CL8'SYSTSPRT'                   SYSTSPRT DDNAME constant.
SPACE1  DC    CL4'0001'                       Default space quantity.
         CEECAA                               Define LE CAA DSECT.
         CEEDSA                               Define LE DSA DSECT.
DAPL     DSECT                                Define DAPL DSECT anchor.
         IKJDAPL                              Map DAPL fields via macro.
DAPL_LEN EQU   *-DAPL                         Compute DAPL size.
DAPB08   DSECT                                Define DAPB08 DSECT anchor.
         IKJDAP08                             Map DAPB08 fields via macro.
DAPB08_LEN EQU *-DAPB08                       Compute DAPB08 size.
DAPB18   DSECT                                Define DAPB18 DSECT anchor.
         IKJDAP18                             Map DAPB18 fields via macro.
DAPB18_LEN EQU *-DAPB18                       Compute DAPB18 size.
WORKAREA DSECT                                Start work area DSECT.
DAPLAREA DS  CL(DAPL_LEN)                     Allocate DAPL storage.
DAPB08AREA DS  CL(DAPB08_LEN)                 Allocate DAPB08 storage.
DAPB18AREA DS  CL(DAPB18_LEN)                 Allocate DAPB18 storage.
DSNBUF  DS    H,CL44                          DSNAME length + 44-byte name.
DDNAME  DS    CL8                             Saved DDNAME buffer.
WORKSIZE EQU  *-WORKAREA                      Compute work area size.
CPPL    DSECT                                 Define CPPL anchor DSECT.
         IKJCPPL                              Map CPPL fields via macro.
         END   TSODALC                        End of module source.
