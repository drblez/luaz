* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
*
* A2CTEST - ASM->C OS-linkage validation (LE-conforming, non-XPLINK).
*
* Object Table:
* | Object  | Kind  | Purpose |
* |---------|-------|---------|
* | A2CTESTS | CSECT | PPA holder for LE entry metadata |
* | A2CTEST  | CSECT | LE subroutine calling C entrypoints via OS plist |
*
* Platform Requirements:
* - LE: required (CEEENTRY/CEETERM).
* - AMODE: 31-bit.
* - EBCDIC: literals are EBCDIC.
* - DDNAME I/O: WTO output appears in JESMSGLG.
*
* Entry point: A2CTEST.
* - Purpose: validate ASM->C calls with OS linkage under LE.
* - Input: no parameters (PLIST=OS, R1=0).
* - Output: RC in R15 (0 success, 8 failure).
* - RC/Special cases: any mismatch returns RC=8.
* - Algorithm notes: build plists in storage and call C entrypoints.
* - Call chain: C main -> A2CTEST -> C entrypoints.

* Define a separate CSECT to hold the PPA for the LE entry.
* This keeps the entrypoint at the CEEENTRY prolog, not at PPA data.
A2CTESTS CSECT
* Keep PPA CSECT AMODE/RMODE consistent with the entry CSECT.
* This avoids binder surprises from default RMODE(24) attributes.
A2CTESTS AMODE 31
A2CTESTS RMODE ANY
* Suppress macro expansion listing.
         PRINT NOGEN
* Declare external C entrypoints.
         EXTRN A2CSCAL
* Declare external C entrypoints.
         EXTRN A2CSTRL
* Declare external C entrypoints.
         EXTRN A2CADD64
* Bind PPA metadata to the real entrypoint name for LE/binder.
* This keeps LE metadata aligned with the A2CTEST entry address.
A2CTPPA  CEEPPA EPNAME=A2CTEST
* Establish LE-conforming prolog for main entry.
* Use PLIST=OS so LE does not parse an external parameter string.
* EXECOPS=NO avoids parsing runtime options from a missing PARM string.
* Change: use C main to initialize LE and remove CEEINT dependency.
* Problem: CEEVINT unresolved during link-edit in this environment.
* Expected effect: keep A2CTEST callable as LE subroutine from C main.
* CEEENTRY opens the A2CTEST entry CSECT for code and data.
* Use a column-72 continuation marker to avoid ASMA017W.
A2CTEST  CEEENTRY PPA=A2CTPPA,MAIN=NO,NAB=NO,PLIST=OS,EXECOPS=NO,      X
               PARMREG=1,BASE=(11),AMODE=31,RMODE=ANY
* Base addressability on the entry CSECT created by CEEENTRY.
* This fixes ASMA307E by addressing labels in the correct CSECT.
         USING A2CTEST,11
* Map LE control blocks.
         USING CEECAA,12
* Map LE DSA.
         USING CEEDSA,13
* Emit start message.
         WTO   'LUZ40110 UTA2C start'
* Load address of plist for cscale.
         LA    1,PLIST1
* Load entry address of A2CSCAL.
         L     15,=V(A2CSCAL)
* Change: preserve base register across C calls.
* Problem: C may clobber R11, causing wrong base for OUT1 access.
* Expected effect: keep A2CTEST base valid after C returns.
         ST    11,SAV11
* Call C function with OS plist in R1.
         BALR  14,15
* Restore base register after C call.
         L     11,SAV11
* Check RC from cscale.
         LTR   15,15
* Change: split RC vs value mismatch for cscale diagnostics.
* Problem: single mismatch message hides whether RC or value failed.
* Expected effect: pinpoint whether plist/out handling or value math failed.
* Branch on nonzero RC.
         BNZ   A2CERR1R
* Load computed result.
         L     2,OUT1
* Compare result with expected value 63.
         CHI   2,63
* Branch on mismatch.
         BNE   A2CERR1V
* Emit success message for cscale.
         WTO   'LUZ40111 UTA2C cscale ok'
* Load address of plist for cstrlen.
         LA    1,PLIST2
* Load entry address of A2CSTRL.
         L     15,=V(A2CSTRL)
* Preserve base register across C calls.
         ST    11,SAV11
* Call C function with OS plist in R1.
         BALR  14,15
* Restore base register after C call.
         L     11,SAV11
* Compare returned length with 5.
         CHI   15,5
* Branch on mismatch.
         BNE   A2CERR2
* Emit success message for cstrlen.
         WTO   'LUZ40112 UTA2C cstrlen ok'
* Load address of plist for cadd64.
         LA    1,PLIST3
* Load entry address of A2CADD64.
         L     15,=V(A2CADD64)
* Preserve base register across C calls.
         ST    11,SAV11
* Call C function with OS plist in R1.
         BALR  14,15
* Restore base register after C call.
         L     11,SAV11
* Check RC from cadd64.
         LTR   15,15
* Branch on nonzero RC.
         BNZ   A2CERR3
* Compare 64-bit result with expected value.
         CLC   OUT64,EXP64
* Branch on mismatch.
         BNE   A2CERR3
* Emit success message for cadd64.
         WTO   'LUZ40113 UTA2C cadd64 ok'
* Emit overall success message.
         WTO   'LUZ40119 UTA2C success'
* Set RC=0 for success.
         SR    15,15
* Return to caller via CEETERM.
         CEETERM RC=(15)
* Emit error message for cscale RC failure.
A2CERR1R WTO   'LUZ40160 UTA2C cscale rc!=0'
* Set RC=8 for failure.
         LHI   15,8
* Return to caller via CEETERM.
         CEETERM RC=(15)
* Emit error message for cscale value mismatch.
A2CERR1V WTO   'LUZ40163 UTA2C cscale value mismatch'
* Set RC=8 for failure.
         LHI   15,8
* Return to caller via CEETERM.
         CEETERM RC=(15)
* Emit error message for cstrlen failure.
A2CERR2  WTO   'LUZ40161 UTA2C cstrlen mismatch'
* Set RC=8 for failure.
         LHI   15,8
* Return to caller via CEETERM.
         CEETERM RC=(15)
* Emit error message for cadd64 failure.
A2CERR3  WTO   'LUZ40162 UTA2C cadd64 mismatch'
* Set RC=8 for failure.
         LHI   15,8
* Return to caller via CEETERM.
         CEETERM RC=(15)
* Place literal pool for V-con literals.
         LTORG
* Define input value A for cscale.
A1       DC    F'7'
* Define input value B for cscale.
B1       DC    F'9'
* Define output storage for cscale.
OUT1     DC    F'0'
* Change: pass pointer value directly for out parameter.
* Problem: OS linkage passes pointer values, not address-of-pointer.
* Expected effect: C receives OUT1 address and writes correctly.
* Define plist for cscale (addresses of cells).
PLIST1   DC    A(A1),A(B1),A(OUT1)
* Define string input for cstrlen (NUL-terminated).
STR1     DC    C'HELLO',X'00'
* Change: pass pointer value directly for cstrlen.
* Problem: extra indirection makes C read pointer cell, not string bytes.
* Expected effect: C receives STR1 address directly.
PLIST2   DC    A(STR1)
* Align 64-bit operands to doubleword to avoid misaligned access.
         DS    0D
* Define 64-bit input A (hi/lo).
A64      DC    F'0',F'16'
* Define 64-bit input B (hi/lo).
B64      DC    F'0',F'32'
* Define 64-bit output storage.
OUT64    DC    F'0',F'0'
* Change: pass pointer value directly for 64-bit out parameter.
* Problem: extra indirection makes C treat pointer cell as target buffer.
* Expected effect: C writes result into OUT64.
PLIST3   DC    A(A64),A(B64),A(OUT64)
* Define expected 64-bit result.
EXP64    DC    F'0',F'48'
* Save area for base register across C calls.
SAV11    DS    F
* Define LE CAA DSECT.
CEECAA   DSECT
* Expand LE CAA mapping.
         CEECAA
* Define LE DSA DSECT.
CEEDSA   DSECT
* Expand LE DSA mapping.
         CEEDSA
* End of A2CTEST module.
         END  A2CTEST
