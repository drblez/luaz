* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
*
* C2AASM - C->ASM OS-linkage validation routines (LE-conforming, non-XPLINK).
*
* Object Table:
* | Object   | Kind  | Purpose |
* |----------|-------|---------|
* | C2AADD2  | CSECT | Add two integers and return sum |
* | C2ASTRL  | CSECT | Compute string length for C caller |
* | C2ASUM   | CSECT | Sum struct Pair fields into output |
* | C2AADD64 | CSECT | Add two 64-bit values via out-parameter |
*
* Platform Requirements:
* - LE: required (CEEENTRY/CEETERM).
* - AMODE: 31-bit.
* - EBCDIC: literals are EBCDIC.
* - DDNAME I/O: none (returns RC to C).
*
* Entry point: C2AADD2.
* - Purpose: add two integers from OS plist and return sum.
* - Input: R1->plist [&a,&b].
* - Output: RC in R15 (sum), CEETERM RC=R2.
* - RC/Special cases: none; always returns sum.
* - Algorithm notes: double-dereference OS plist for values.
*
* C2AADD2 routine.
* Define control section for C2AADD2.
C2AADD2S CSECT
* Set addressing mode for C2AADD2S control section.
C2AADD2S AMODE 31
* Allow load above/below 16M for C2AADD2S control section.
C2AADD2S RMODE ANY
* Define PPA for LE-conforming entry.
ADD2PPA  CEEPPA EPNAME=C2AADD2
* Establish LE-conforming prolog with entrypoint name and AMODE/RMODE.
C2AADD2  CEEENTRY PPA=ADD2PPA,MAIN=NO,PLIST=OS,PARMREG=1,BASE=(11),    X
               AMODE=31,RMODE=ANY
* Enable code base addressability for the entrypoint label base.
         USING C2AADD2,11
* Map LE control blocks.
         USING CEECAA,12
* Map LE DSA.
         USING CEEDSA,13
* Load address of argument cell for a from plist[0].
         L     3,0(,1)
* Clear HOB on plist entry with an immediate mask to keep address valid.
         NILF  3,X'7FFFFFFF'
* Load a value from its cell.
         L     4,0(3)
* Load address of argument cell for b from plist[1].
         L     3,4(,1)
* Clear HOB on plist entry with an immediate mask to keep address valid.
         NILF  3,X'7FFFFFFF'
* Load b value from its cell.
         L     5,0(3)
* Add a and b.
         AR    4,5
* Move sum into RC register.
         LR    2,4
* Return to caller with RC in R2 via CEETERM.
         CEETERM RC=(2)
* Place literal pool within C2AADD2 range.
         LTORG
* Drop base registers before next CEEENTRY as required by IBM.
         DROP 11,12,13
*
* Entry point: C2ASTRL.
* - Purpose: compute length of NUL-terminated string.
* - Input: R1->plist [s], where s is string pointer.
* - Output: RC in R15 (length), CEETERM RC=R2.
* - RC/Special cases: returns 0 for empty string.
* - Algorithm notes: byte scan until X'00'.
*
* C2ASTRL routine.
* Define control section for C2ASTRL.
C2ASTRLS CSECT
* Set addressing mode for C2ASTRLS control section.
C2ASTRLS AMODE 31
* Allow load above/below 16M for C2ASTRLS control section.
C2ASTRLS RMODE ANY
* Define PPA for LE-conforming entry.
STRLPPA  CEEPPA EPNAME=C2ASTRL
* Establish LE-conforming prolog with entrypoint name and AMODE/RMODE.
C2ASTRL  CEEENTRY PPA=STRLPPA,MAIN=NO,PLIST=OS,PARMREG=1,BASE=(11),    X
               AMODE=31,RMODE=ANY
* Enable code base addressability for the entrypoint label base.
         USING C2ASTRL,11
* Map LE control blocks.
         USING CEECAA,12
* Map LE DSA.
         USING CEEDSA,13
* Load address of argument cell for s from plist[0].
         L     3,0(,1)
* Clear HOB on plist entry with an immediate mask to get string pointer.
         NILF  3,X'7FFFFFFF'
* Clear length counter.
         SR    2,2
* Compare current byte to NUL.
STRLLOOP CLI   0(3),X'00'
* Exit loop on NUL.
         BE    STRLDONE
* Advance string pointer.
         LA    3,1(3)
* Increment length counter.
         LA    2,1(2)
* Loop to next byte.
         B     STRLLOOP
* Return length via CEETERM using RC in R2.
STRLDONE CEETERM RC=(2)
* Place literal pool within C2ASTRL range.
         LTORG
* Drop base registers before next CEEENTRY as required by IBM.
         DROP 11,12,13
*
* Entry point: C2ASUM.
* - Purpose: sum two struct fields into output field.
* - Input: R1->plist [p], where p is struct pointer.
* - Output: RC in R15 (0), CEETERM RC=0.
* - RC/Special cases: RC=0 on success.
* - Algorithm notes: struct layout [a@0,b@4,sum@8].
*
* C2ASUM routine.
* Define control section for C2ASUM.
C2ASUMS  CSECT
* Set addressing mode for C2ASUMS control section.
C2ASUMS AMODE 31
* Allow load above/below 16M for C2ASUMS control section.
C2ASUMS RMODE ANY
* Define PPA for LE-conforming entry.
SUMPPA   CEEPPA EPNAME=C2ASUM
* Establish LE-conforming prolog with entrypoint name and AMODE/RMODE.
C2ASUM   CEEENTRY PPA=SUMPPA,MAIN=NO,PLIST=OS,PARMREG=1,BASE=(11),     X
               AMODE=31,RMODE=ANY
* Enable code base addressability for the entrypoint label base.
         USING C2ASUM,11
* Map LE control blocks.
         USING CEECAA,12
* Map LE DSA.
         USING CEEDSA,13
* Load address of argument cell for p from plist[0].
         L     3,0(,1)
* Clear HOB on plist entry with an immediate mask to get struct pointer.
         NILF  3,X'7FFFFFFF'
* Load a field at offset 0.
         L     4,0(3)
* Load b field at offset 4.
         L     5,4(3)
* Add fields.
         AR    4,5
* Store sum at offset 8.
         ST    4,8(3)
* Set RC=0 in R2 for success.
         SR    2,2
* Return RC=0 via CEETERM using RC in R2.
         CEETERM RC=(2)
* Place literal pool within C2ASUM range.
         LTORG
* Drop base registers before next CEEENTRY as required by IBM.
         DROP 11,12,13
*
* Entry point: C2AADD64.
* - Purpose: add two 64-bit values and store into out-parameter.
* - Input: R1->plist [&a,&b,out], out is pointer value.
* - Output: RC in R15 (0/8), CEETERM RC=R2.
* - RC/Special cases: RC=8 when out pointer is NULL.
* - Algorithm notes: operate on hi/lo fullwords (big-endian).
*
* C2AADD64 routine.
* Define control section for C2AADD64.
C2A64S   CSECT
* Set addressing mode for C2A64S control section.
C2A64S AMODE 31
* Allow load above/below 16M for C2A64S control section.
C2A64S RMODE ANY
* Define PPA for LE-conforming entry.
ADD64PPA CEEPPA EPNAME=C2AADD64
* Establish LE-conforming prolog with entrypoint name and AMODE/RMODE.
C2AADD64 CEEENTRY PPA=ADD64PPA,MAIN=NO,PLIST=OS,PARMREG=1,BASE=(11),   X
               AMODE=31,RMODE=ANY
* Enable code base addressability for the entrypoint label base.
         USING C2AADD64,11
* Map LE control blocks.
         USING CEECAA,12
* Map LE DSA.
         USING CEEDSA,13
* Load address of argument cell for a from plist[0].
         L     3,0(,1)
* Clear HOB on plist entry with an immediate mask to keep address valid.
         NILF  3,X'7FFFFFFF'
* Use a cell address directly for by-value 64-bit operand a.
* Load a high word.
         L     4,0(3)
* Load a low word.
         L     5,4(3)
* Load address of argument cell for b from plist[1].
         L     3,4(,1)
* Clear HOB on plist entry with an immediate mask to keep address valid.
         NILF  3,X'7FFFFFFF'
* Use a cell address directly for by-value 64-bit operand b.
* Load b high word.
         L     6,0(3)
* Load b low word.
         L     7,4(3)
* Compute low sum (mod 2^32).
         LR    8,5
* Add low words.
         ALR   8,7
* Clear carry register.
         SR    9,9
* Compare low sum with original low word.
         CLR   8,5
* Set carry if low sum wrapped.
         BNL   ADD64NC
* Set carry to one.
         LHI   9,1
* Mark no-carry point.
ADD64NC  DS    0H
* Compute high sum.
         LR    10,4
* Add high words.
         ALR   10,6
* Add carry.
         ALR   10,9
* Load out pointer value from plist[2].
         L     3,8(,1)
* Clear HOB on plist entry with an immediate mask to get out pointer.
         NILF  3,X'7FFFFFFF'
* Check for NULL out pointer value.
         LTR   3,3
* Branch to error on NULL.
         BZ    ADD64ERR
* Store high word to output.
         ST    10,0(3)
* Store low word to output.
         ST    8,4(3)
* Set RC=0 for success.
         SR    2,2
* Return via CEETERM with RC=0 in R2.
         CEETERM RC=(2)
* Place literal pool within C2AADD64 range.
         LTORG
* Set RC=8 for NULL out pointer.
ADD64ERR LHI   2,8
* Return via CEETERM with RC=8 in R2.
         CEETERM RC=(2)
* Place literal pool within C2AADD64 range after error exit.
         LTORG
* Drop base registers after last CEEENTRY as required by IBM.
         DROP 11,12,13
*
* Define LE CAA DSECT.
CEECAA   DSECT
* Expand LE CAA mapping.
         CEECAA
* Define LE DSA DSECT.
CEEDSA   DSECT
* Expand LE DSA mapping.
         CEEDSA
* End of C2AASM module.
         END
