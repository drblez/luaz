* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
*
* Minimal write test for ASM storage access.
*
* Object Table:
* | Object | Kind | Purpose |
* | TSOWRT | CSECT | Write a test byte into a caller buffer |
*
* User Actions:
* - Link with AC=1 into APF-authorized library.
* - Add TSOWRT to AUTHPGM/AUTHTSF in IKJTSO00.
* - Activate IKJTSO00 changes before running.
*
* Emit assembler listing for debugging.
         PRINT GEN
* Change note: move AMODE/RMODE into CEEENTRY and align with
* LE_C_HLASM_RULES for CSECT/base/HOB.
* Problem: standalone AMODE/RMODE conflicts with CEEENTRY expansion
* (ASMA186E) and literal-based HOB masking.
* Expected effect: ASMA90 RC=0 with stable addressability and correct
* plist pointer handling.
* Impact: TSOWRT uses CEEENTRY base and NILF for HOB.
* Ref: src/tsowrt.md#ceeentry-amode-rmode
* Define entry point control section via LE entry macro.
* Define TSOWRT control section.
TSOWRT   CSECT
* Register name aliases.
R0       EQU   0
* Register name aliases.
R1       EQU   1
* Register name aliases.
R2       EQU   2
* Register name aliases.
R3       EQU   3
* Register name aliases.
R4       EQU   4
* Register name aliases.
R5       EQU   5
* Register name aliases.
R6       EQU   6
* Register name aliases.
R7       EQU   7
* Register name aliases.
R8       EQU   8
* Register name aliases.
R9       EQU   9
* Register name aliases.
R10      EQU   10
* Register name aliases.
R11      EQU   11
* Register name aliases.
R12      EQU   12
* Register name aliases.
R13      EQU   13
* Register name aliases.
R14      EQU   14
* Register name aliases.
R15      EQU   15
* LE prolog with PPA registration (OS plist, AMODE/RMODE via CEEENTRY).
TSOWRT   CEEENTRY PPA=TSWPPA,MAIN=NO,PLIST=OS,PARMREG=1,BASE=(11),     X
               AMODE=31,RMODE=ANY
* CAA addressability for LE services.
         USING CEECAA,R12
* DSA addressability for LE services.
         USING CEEDSA,R13
* CSECT base addressability from CEEENTRY.
         USING TSOWRT,R11
* Preserve caller parameter list pointer.
         LR    R8,R1
* Load buffer pointer from plist entry.
         L     R2,0(R8)        Load buf pointer.
* Load length pointer from plist entry.
         L     R3,4(R8)        Load len pointer.
* Load rc pointer from plist entry.
         L     R4,8(R8)        Load rc pointer.
* Clear high bit on last plist entry.
         NILF  R4,X'7FFFFFFF'  Clear HOB via NILF.
* Validate buffer pointer is nonzero.
         LTR   R2,R2
* Branch if buffer pointer is NULL.
         BZ    FAIL
* Load test fullword value.
         L     R7,=F'0'
* Store test fullword into caller buffer.
         ST    R7,0(R2)
* Validate rc pointer is nonzero.
         LTR   R4,R4
* Branch if rc pointer is NULL.
         BZ    DONE
* Store success rc for caller.
         L     R7,=F'0'
* Store rc value.
         ST    R7,0(R4)
* Return via LE epilog.
DONE     CEETERM RC=0
* Store failure rc when buffer is invalid.
FAIL     LTR   R4,R4
* Skip rc store if rc pointer is NULL.
         BZ    DONE
* Load generic error rc.
         L     R7,=F'-1'
* Store rc value.
         ST    R7,0(R4)
* Return via LE epilog.
         B     DONE
* Emit literal pool for constants.
         LTORG
* Define LE PPA for this routine.
TSWPPA   CEEPPA
* LE CAA DSECT anchor (no storage).
CEECAA   DSECT
* LE CAA layout definition.
         CEECAA
* LE DSA DSECT anchor (no storage).
CEEDSA   DSECT
* LE DSA layout definition.
         CEEDSA
* End of module.
         END
