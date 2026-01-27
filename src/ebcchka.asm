* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
*
* EBCCHKA -- verify ASCII to EBCDIC conversion for FTP-transferred ASM.
*
* Object Table:
* | Object  | Kind  | Purpose |
* |---------|-------|---------|
* | EBCCHKA | CSECT | Program entry; output hex bytes for literal "ABC"
* |
*
* Platform Requirements:
* - LE: not required (MVS linkage).
* - AMODE: 31-bit.
* - EBCDIC: literal bytes expected in EBCDIC.
* - DDNAME I/O: WTO output appears in JESMSGLG.
*
* Entry point: EBCCHKA.
* - Purpose: output hex codes for literal "ABC" and return RC.
* - Input: R1 may point to OS parameter list; not used.
* - Output: R15=0 when bytes are C1/C2/C3, R15=8 on mismatch.
* - RC/Special cases: mismatch triggers LUZ40083 message.
* - Algorithm notes: build hex text from literal bytes and send via
* WTO.
*
* Define code section for EBCCHKA entry.
EBCCHKA  CSECT
* Define 31-bit addressing mode for the test program.
EBCCHKA  AMODE 31
* Allow load above/below 16M as required by system.
EBCCHKA  RMODE ANY
* Suppress macro expansion listing for concise output.
         PRINT NOGEN
* Preserve caller registers 14-12 in caller save area.
         STM   14,12,12(13)
* Establish base register with current instruction address.
         BALR  12,0
* Define base label for addressability.
EBCBASE  EQU   *
* Enable base register for this CSECT.
         USING EBCBASE,12
* Allocate and chain a local save area.
         LA    15,SAVE
* Back-chain caller save area pointer.
         ST    13,4(15)
* Forward-chain new save area pointer.
         ST    15,8(13)
* Switch to local save area.
         LR    13,15
* Initialize output buffer with template text.
         MVC   BUFFER(TEMPLEN),TEMPLATE
* Initialize pointer to literal bytes.
         LA    2,STRABC
* Initialize byte count to three characters.
         LHI   3,3
* Initialize pointer to first hex digit in output buffer.
         LA    4,HEXPOS
* Clear working register for byte extraction.
HEXLOOP  XR    5,5
* Load one byte from the literal.
         IC    5,0(2)
* Copy byte to preserve original for low nibble.
         LR    6,5
* Shift high nibble into low bits.
         SRL   6,4
* Mask low nibble into low bits.
         N     5,=X'0000000F'
* Translate high nibble to hex character.
         IC    7,HEXTAB(6)
* Store high nibble character into buffer.
         STC   7,0(4)
* Translate low nibble to hex character.
         IC    7,HEXTAB(5)
* Store low nibble character into buffer.
         STC   7,1(4)
* Advance buffer pointer to next hex field.
         LA    4,3(4)
* Advance literal pointer to next byte.
         LA    2,1(2)
* Decrement byte count and loop until complete.
         BCT   3,HEXLOOP
* Emit the assembled byte dump message via WTO.
         WTO   TEXT=(BUFFER,),ROUTCDE=11,MF=(E,WTOBUF)
* Compare literal bytes to expected EBCDIC values.
         CLC   STRABC(3),EXPABC
* Branch to success path when bytes match.
         BE    OKRC
* Emit mismatch diagnostic message when bytes differ.
         WTO   TEXT=(ERRMSG,),ROUTCDE=11,MF=(E,WTOERR)
* Set nonzero return code for mismatch.
         LHI   15,8
* Branch to common epilog.
         B     DONE
* Set success return code.
OKRC     LHI   15,0
* Restore caller save area and registers.
DONE     L     13,4(13)
* Restore caller registers 14-12.
         LM    14,12,12(13)
* Return to caller with RC in R15.
         BR    14
* Define save area for this program.
SAVE     DS    18F
* Define prefix text for computing hex offset.
PFXTXT   DC    C'LUZ40081 EBCCHK ASM bytes: '
* Define template text with placeholder hex digits.
TEMPLATE DC    C'LUZ40081 EBCCHK ASM bytes: 00 00 00'
* Define template length for initialization MVC.
TEMPLEN  EQU   L'TEMPLATE
* Define output buffer (blank-padded to 71 bytes for L-line type).
BUFFER   DC    CL71' '
* Define first hex digit position relative to buffer start.
HEXPOS   EQU   BUFFER+L'PFXTXT
* Define hex digit translation table.
HEXTAB   DC    C'0123456789ABCDEF'
* Define expected EBCDIC bytes for literal comparison.
EXPABC   DC    X'C1C2C3'
* Define literal bytes under test.
STRABC   DC    C'ABC'
* Define mismatch message text.
ERRMSG   DC    C'LUZ40083 EBCCHK ASM mismatch expected=C1 C2 C3'
* Define WTO parameter list for buffer output (single L-line).
WTOBUF   WTO   TEXT=(,L),ROUTCDE=11,MF=L
* Define WTO parameter list for error output (single L-line).
WTOERR   WTO   TEXT=(,L),ROUTCDE=11,MF=L
* Mark end of module.
         END   EBCCHKA
