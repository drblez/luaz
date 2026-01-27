* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
*
* TSO/E STACK service routine bridge for C (OS linkage).
*
* Object Table:
* | Object | Kind | Purpose |
* |--------|------|---------|
* | TSOSTK | CSECT | Invoke STACK to set OUTDD/CLOSE/DELETE using CPPL
* |
*
* Platform Requirements:
* - LE: required (CEEENTRY/CEETERM).
* - AMODE: 31-bit.
* - EBCDIC: DDNAME argument must be EBCDIC.
*
* Entry point: TSOSTK (LE-conforming, OS linkage).
* - Purpose: route TSO/E command output to a dataset via STACK.
* - Input: R1 -> OS plist.
*   - plist[0] -> CPPL pointer value (from LUACMD/IKJTSOEV).
*   - plist[1] -> OUTDD pointer value (8-byte DDNAME, may be NULL).
* - plist[2] -> op value (by-value int; 0=OUTDD, 1=CLOSE, 2=DELETE
* TOP).
* - Output: R15 = STACK return code (0=OK, nonzero=error, -1=param
* error).
* - Notes: uses STACK execute form with UPT/ECT from CPPL.
*
* Emit assembler listing for debugging.
         PRINT GEN               Emit assembler listing for debug.
* Define entry point control section.
TSOSTK   CSECT Define            control section for TSOSTK.
* Change note: add minimal STACK bridge for OUTDD routing.
* Problem: C cannot call IKJSTCK directly because R1 must point to
* IOPL.
* Expected effect: STACK I/O is callable from C with OS linkage plist.
* Impact: tso.cmd can redirect output to a preallocated DDNAME.
* Ref: src/tsostk.asm.md#stack-call
* Change note: fix CEEENTRY continuation/END operand formatting for
* HLASM.
* Problem: incorrect continuation marker and END operand caused ASMA
* errors.
* Expected effect: TSOSTK assembles cleanly and OBJ is produced for
* linkage.
* Impact: LUAEXEC/LUACMD can resolve TSOSTK at link-edit.
* Enter LE, OS linkage for TSOSTK entry.
TSOSTK   CEEENTRY PPA=TSKPPA,MAIN=NO,AUTO=4,PLIST=OS,PARMREG=1,        X
               BASE=(11),AMODE=31,RMODE=ANY
* Register aliases.
* Define register 0 alias.
R0       EQU   0                 Register 0 alias.
* Define register 1 alias.
R1       EQU   1                 Register 1 alias.
* Define register 2 alias.
R2       EQU   2                 Register 2 alias.
* Define register 3 alias.
R3       EQU   3                 Register 3 alias.
* Define register 4 alias.
R4       EQU   4                 Register 4 alias.
* Define register 5 alias.
R5       EQU   5                 Register 5 alias.
* Define register 6 alias.
R6       EQU   6                 Register 6 alias.
* Define register 7 alias.
R7       EQU   7                 Register 7 alias.
* Define register 8 alias.
R8       EQU   8                 Register 8 alias.
* Define register 9 alias.
R9       EQU   9                 Register 9 alias.
* Define register 10 alias.
R10      EQU   10                Register 10 alias.
* Define register 11 alias.
R11      EQU   11                Register 11 alias.
* Define register 12 alias.
R12      EQU   12                Register 12 alias.
* Define register 13 alias.
R13      EQU   13                Register 13 alias.
* Define register 14 alias.
R14      EQU   14                Register 14 alias.
* Define register 15 alias.
R15      EQU   15                Register 15 alias.
* Enable CAA addressability.
         USING CEECAA,R12        Map CAA via R12 for LE services.
* Enable DSA addressability.
         USING CEEDSA,R13        Map DSA via R13 for LE services.
* Enable base addressability from CEEENTRY base register.
         USING TSOSTK,R11        Map CSECT via R11 base register.
* Preserve caller parameter list pointer.
         LR    R8,R1             Save plist pointer in R8.
* Validate caller parameter list pointer.
         LTR   R8,R8             Test plist pointer for NULL.
* Fail if plist is missing.
         BZ    STK_FAIL          Branch on missing plist.
* Load CPPL pointer from plist entry.
         L     R2,0(R8)          Load CPPL pointer from plist slot 0.
* Load OUTDD pointer from plist entry.
         L     R3,4(R8)          Load OUTDD pointer from plist slot 1.
* Load op-value cell pointer from plist entry (HOB may be set).
         L     R4,8(R8)   Load op-value cell pointer from plist slot 2.
* Clear HOB on op-value pointer.
         NILF  R4,X'7FFFFFFF'    Clear HOB on op-value pointer.
* Clear HOB on OUTDD pointer (defensive).
         NILF  R3,X'7FFFFFFF'    Clear HOB on OUTDD pointer if set.
* Validate CPPL pointer is nonzero.
         LTR   R2,R2             Test CPPL pointer for NULL.
* Fail if CPPL pointer is missing.
         BZ    STK_FAIL          Branch on missing CPPL pointer.
* Validate op-value pointer is nonzero.
         LTR   R4,R4             Test op-value pointer for NULL.
* Fail if op-value pointer is missing.
         BZ    STK_FAIL          Branch on missing op-value pointer.
* Load op value from by-value cell.
         L     R6,0(R4)          Load op selector value from cell.
* Branch if op is nonzero.
         LTR   R6,R6             Test op selector for zero.
* Op=0 -> OUTDD path.
         BNZ   STK_OP_DISP       Branch to nonzero op dispatch.
* Validate OUTDD pointer for OUTDD operation.
         LTR   R3,R3             Test OUTDD pointer for NULL.
* Fail if OUTDD pointer is missing.
         BZ    STK_FAIL          Branch on missing OUTDD pointer.
* Map CPPL to load UPT/ECT pointers.
         USING CPPL,R2           Map CPPL to access UPT/ECT fields.
* Load UPT pointer from CPPL.
         L     R7,CPPLUPT        Fetch UPT pointer from CPPL.
* Load ECT pointer from CPPL.
         L     R9,CPPLECT        Fetch ECT pointer from CPPL.
* Drop CPPL mapping.
         DROP  R2                Release CPPL mapping register.
* Change note: request sequential OUTDD for STACK routing.
* Problem: implicit DATASET defaults can leave OUTDD inactive.
* Expected effect: STACK routes output to the sequential OUTDD dataset.
* Impact: tso.cmd captures command output in the temp DDNAME.
* Ref: src/tsostk.asm.md#stack-outdd-seq
* Call STACK to route output to OUTDD (sequential).
         STACK UPT=(R7),ECT=(R9),ECB=STKECB,DATASET=(OUTDD=(R3),SEQ),  X
               MF=(E,STKOUTL)      Invoke STACK to set OUTDD.
* Branch to common return.
         B     STK_RET           Branch to return handling.
* Dispatch nonzero op values.
STK_OP_DISP DS 0H                Dispatch for nonzero op values.
* Compare op to CLOSE selector.
         CHI   R6,1              Compare op value to CLOSE selector.
* Branch to CLOSE path.
         BE    STK_CLOSE         Branch to CLOSE when op=1.
* Compare op to DELETE selector.
         CHI   R6,2              Compare op value to DELETE selector.
* Branch to DELETE path.
         BE    STK_DELETE        Branch to DELETE when op=2.
* Unknown op: fail.
         B     STK_FAIL          Branch on unknown op value.
* CLOSE path for dataset output.
STK_CLOSE DS   0H                Entry for CLOSE operation.
* Map CPPL to load UPT/ECT pointers.
         USING CPPL,R2           Map CPPL to access UPT/ECT fields.
* Load UPT pointer from CPPL.
         L     R7,CPPLUPT        Fetch UPT pointer from CPPL.
* Load ECT pointer from CPPL.
         L     R9,CPPLECT        Fetch ECT pointer from CPPL.
* Drop CPPL mapping.
         DROP  R2                Release CPPL mapping register.
* Call STACK to close dataset DCBs.
         STACK UPT=(R7),ECT=(R9),ECB=STKECB,DATASET=(CLOSE),           X
               MF=(E,STKCLSL)      Invoke STACK to close dataset DCBs.
* Branch to common return.
         B     STK_RET           Branch to return handling.
* DELETE path to remove top element.
STK_DELETE DS  0H                Entry for DELETE operation.
* Map CPPL to load UPT/ECT pointers.
         USING CPPL,R2           Map CPPL to access UPT/ECT fields.
* Load UPT pointer from CPPL.
         L     R7,CPPLUPT        Fetch UPT pointer from CPPL.
* Load ECT pointer from CPPL.
         L     R9,CPPLECT        Fetch ECT pointer from CPPL.
* Drop CPPL mapping.
         DROP  R2                Release CPPL mapping register.
* Call STACK to delete the top element.
         STACK UPT=(R7),ECT=(R9),ECB=STKECB,DELETE=TOP,                X
               MF=(E,STKDELL)      Invoke STACK to delete top element.
* Branch to common return.
         B     STK_RET           Branch to return handling.
* Return to caller with STACK RC.
STK_RET  DS    0H                Common return path.
* Move STACK RC into CEETERM register.
         LR    R2,R15            Move STACK return code to R2.
* Return RC via LE epilog.
         CEETERM RC=(R2)         Return with STACK RC in R15.
* Fail path for invalid parameters.
STK_FAIL DS    0H                Common failure path.
* Load -1 return code for parameter errors.
         LHI   R2,-1             Set failure RC for invalid parameters.
* Return RC via LE epilog.
         CEETERM RC=(R2)         Return with failure RC in R15.
* Change note: add explicit STPL lists with STPLSTPB initialized.
* Problem: STPLSTPB was zero, STACK execute form abended with 0C4.
* Expected effect: STACK uses valid STPB for OUTDD/CLOSE/DELETE.
* Impact: tso.cmd output capture no longer abends in TSOSTK.
* Ref: src/tsostk.asm.md#stack-stpl
* STPL list for OUTDD operation (UPT/ECT/ECB filled at runtime).
STKOUTL  DS    0F                Align STPL for OUTDD.
         DC    A(0,0,0,STKOUTB)  STPLUPT/STPLECT/STPLECB/STPLSTPB.
* STPB list form for OUTDD operation (zeroed STPB).
STKOUTB  STACK MF=L              Build STPB for OUTDD.
* STPL list for CLOSE operation (UPT/ECT/ECB filled at runtime).
STKCLSL  DS    0F                Align STPL for CLOSE.
         DC    A(0,0,0,STKCLSB)  STPLUPT/STPLECT/STPLECB/STPLSTPB.
* STPB list form for CLOSE operation (zeroed STPB).
STKCLSB  STACK MF=L              Build STPB for CLOSE.
* STPL list for DELETE operation (UPT/ECT/ECB filled at runtime).
STKDELL  DS    0F                Align STPL for DELETE.
         DC    A(0,0,0,STKDELB)  STPLUPT/STPLECT/STPLECB/STPLSTPB.
* STPB list form for DELETE operation (zeroed STPB).
STKDELB  STACK MF=L              Build STPB for DELETE.
* Event control block storage for STACK.
STKECB   DC    F'0'              Provide ECB storage for STACK.
* Define LE PPA for this routine.
TSKPPA   CEEPPA Define           LE PPA for TSOSTK.
* LE CAA DSECT anchor (no storage).
CEECAA   DSECT Anchor            for CAA mapping.
* LE CAA layout definition.
         CEECAA Map              CAA fields for LE.
* LE DSA DSECT anchor (no storage).
CEEDSA   DSECT Anchor            for DSA mapping.
* LE DSA layout definition.
         CEEDSA Map              DSA fields for LE.
* CPPL DSECT anchor (no storage).
CPPL     DSECT Anchor            for CPPL mapping.
* CPPL layout definition.
         IKJCPPL Map             CPPL fields from SYS1.MACLIB.
* End of module.
         END   TSOSTK            End of TSOSTK assembly.
