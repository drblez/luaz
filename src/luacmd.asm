* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
*
* LUACMD -- TSO command processor wrapper for LUAEXEC.
*
* Object Table:
* | Object | Kind | Purpose |
* |--------|------|---------|
* | LUACMD | CSECT | Parse CPPL and dispatch LE bridge |
* | LUACMDL | CSECT | LE bridge calling LUAEXEC runner |
*
* User Actions:
* - Link with AC=1 into APF-authorized library if required by site
* policy.
* - Add LUACMD to AUTHPGM/AUTHTSF and AUTHCMD in IKJTSO00.
* - Run under IKJEFT01 (TMP) for SYSTSPRT output.
*
* Platform Requirements:
* - LE: required (CEEENTRY for LE bridge).
* - AMODE: 31-bit (TSO command processors).
* - EBCDIC: command buffer and literals.
* - DDNAME I/O: relies on SYSTSPRT for output.
*
* Entry point: LUACMD (TSO command processor).
* - Purpose: parse CPPL command buffer and dispatch to LE bridge
* (LUACMDL).
* - Input: R1 points to CPPL control block; CPPLCBUF contains
* length/offset.
* - Output: R15 return code propagated from LUAEXRUN (typically 0/8).
* - Special cases: no operands or short buffer -> pass empty line
* pointer with zero length.
* - Notes: LUACMD is non-LE; LUACMDL performs LE-conforming work.
* Change note: wrapped comments to keep columns 1-71 and avoid
* ASMA144E continuations; no functional behavior change.
* Define LUACMD control section.
LUACMD  CSECT
* Set 31-bit addressing mode.
LUACMD  AMODE 31
* Allow load above/below 16M.
LUACMD  RMODE ANY
R0      EQU   0                Reg0 alias.
R1      EQU   1                Reg1 alias.
R2      EQU   2                Reg2 alias.
R3      EQU   3                Reg3 alias.
R4      EQU   4                Reg4 alias.
R5      EQU   5                Reg5 alias.
R6      EQU   6                Reg6 alias.
R7      EQU   7                Reg7 alias.
R8      EQU   8                Reg8 alias.
R9      EQU   9                Reg9 alias.
* Define register 10 alias.
R10     EQU   10               Reg10 alias.
* Define register 11 alias.
R11     EQU   11               Reg11 alias.
* Define register 12 alias.
R12     EQU   12               Reg12 alias.
* Define register 13 alias.
R13     EQU   13               Reg13 alias.
* Define register 14 alias.
R14     EQU   14               Reg14 alias.
* Define register 15 alias.
R15     EQU   15               Reg15 alias.
* External C entry for LUAEXEC runner.
         EXTRN LUAEXRUN        Declare LUAEXRUN entry.
* External C entry for CPPL setter.
         EXTRN TSONCPPL        Declare TSONCPPL entry.
* Save caller registers.
         STM   R14,R12,12(R13) Save caller regs.
* Establish LUACMD base register for addressability.
         BALR  R12,0           Set base register.
* Define LUACMD base alias to avoid overlapping USING.
LUCBASE  EQU   *               Base label for LUACMD.
         USING LUCBASE,R12     Map LUACMD base.
* Point to local save area.
         LA    R15,SAVE        Load local save area.
         ST    R13,4(R15)      Back-chain save area.
         ST    R15,8(R13)      Forward-chain save area.
* Switch to local save area.
         LR    R13,R15         Activate local save area.
* Save CPPL address in R10.
         LR    R10,R1          Copy CPPL pointer.
* Store CPPL pointer for LE bridge usage.
         ST    R10,CPPLPTR     Save CPPL pointer.
         USING CPPL,R10        Map CPPL control block.
* Algorithm: parse CPPL command buffer to derive operand
* pointer/length.
* - If CPPLCBUF is NULL or too short, clear PARMPTR/PARMLENFW.
* - Otherwise compute operand pointer/length from header fields.
* Load CPPL command buffer pointer.
         L     R2,CPPLCBUF     Load CPPL command buffer.
* Validate command buffer pointer.
         LTR   R2,R2           Test command buffer pointer.
* Default to no-operand invocation.
         BZ    ONLYPFX         Branch if no command buffer.
         LH    R3,0(R2)        Load buffer length.
         N     R3,=X'0000FFFF' Zero-extend length.
* Ensure header length present.
         CHI   R3,4            Validate header length.
* Branch if header too short.
         BL    ONLYPFX         Branch if too short.
         LH    R5,2(R2)        Load operand offset.
         N     R5,=X'0000FFFF' Zero-extend offset.
         AHI   R3,-4           Remove header length.
         LTR   R3,R3           Validate text length.
         BZ    ONLYPFX         Branch if no text.
* Check offset vs text length.
         CR    R5,R3           Compare offset to length.
         BNL   ONLYPFX         Branch if no operands.
         LA    R4,4(R2)        Point to command text.
         AR    R4,R5           Advance to operands.
* Compute operand length.
         SR    R3,R5           Compute operand length.
* Branch with operands ready.
         B     CMDREADY        Branch to CMDREADY.
ONLYPFX  LA    R4,EMPTYCMD     Load empty line address.
         ST    R4,PARMPTR      Store empty line pointer.
         XC    PARMLENFW,PARMLENFW Clear parm length.
         B     CALLLE          Branch to LE bridge.
CMDREADY ST    R4,PARMPTR      Store parm pointer.
         ST    R3,PARMLENFW    Store parm length.
* Algorithm: enter LE bridge to call LUAEXRUN (MODE=TSO injected).
* - Drop CPPL/WORKAREA mappings before CEEENTRY.
* - Call LUACMDL and return its RC to the caller.
* Drop CPPL addressability before LE entry.
CALLLE   DS    0H              LE bridge entry point.
         DROP  CPPL            Drop CPPL mapping.
* Clear parm register for CEEENTRY.
         SR    R1,R1           Clear R1 for CEEENTRY.
         L     R15,=V(LUACMDL) Load LE bridge entry.
         BALR  R14,R15         Call LE bridge.
* Change note: preserve LUACMDL RC across return path.
* Problem: R15 must return LUACMDL RC to TMP.
* Expected effect: LUACMD returns LUACMDL RC intact.
         ST    R15,RCMD        Save LUACMDL RC immediately.
         B     EPILOG          Branch to epilog.
* Restore save-area chain and return to caller.
EPILOG   L     R13,4(R13)      Restore caller save area.
         LM    R14,R12,12(R13) Restore caller registers.
* Change note: restore CPPL in R1 after LM clobbers it.
* Problem: LM restores R1 from save area, not CPPL.
* Expected effect: TMP sees CPPL in R1 on return.
         L     R1,CPPLPTR      Restore CPPL pointer in R1.
* Change note: restore RC in R15 after LM clobbers it.
* Problem: LM restores stale R15 from save area.
* Expected effect: LUACMD returns correct RC to TMP.
         L     R15,RCMD        Restore LUACMDL RC in R15.
         BR    R14             Return to caller.
*
* Place literal pool before LUACMD storage to keep literals
* addressable for LUACMD code and macros.
         LTORG                 Emit literal pool near LUACMD code.
* LUACMD storage (CP entry).
*
* Reserve save area storage.
SAVE     DS    18F             Save area storage.
WORKAREA DS    0F              Align work area anchor.
PARMPTR  DS    F               Operand pointer cell.
PARMLENFW DS   F               Operand length cell.
CPPLPTR  DS    F               CPPL pointer cell.
RCMD     DS    F               Return code cell for LUACMD.
EMPTYCMD DC    X'00'           Empty line buffer.
* LE plist pointer placeholder.
LEPLIST  DC    A(DUMMY)        Placeholder plist pointer.
DUMMY    DC    F'0'            Dummy parameter storage.
*
* LUACMD storage DSECT for LUACMDL aliasing.
LUACMDS  DSECT                 LUACMD storage alias DSECT.
SAVEDS   DS    18F             Alias save area storage.
WORKAREADS DS  0F              Alias work area alignment.
PARMPTRDS DS   F               Alias operand pointer cell.
PARMLENFWDS DS F               Alias operand length cell.
CPPLPTRDS DS   F               Alias CPPL pointer cell.
RCMDDS   DS    F               Alias return code cell.
EMPTYCMDDS DS  X               Alias empty command byte.
         DS    0F              Align alias fields.
LEPLISTDS DS   F               Alias plist placeholder.
DUMMYDS  DS    F               Alias dummy storage.
*
* Entry point: LUACMDL (LE bridge).
* - Purpose: set CPPL in native backend and call LUAEXRUN with OS
*   plist.
* - Input: no parameters (PLIST=NONE); uses LUACMD storage
*   (CPPLPTR/PARMPTR).
* - Output: R15 return code from LUAEXRUN (0/8 typical).
* - Special cases: NULL PARMPTR or zero length is allowed.
* - Notes: LUAZ_MODE is set to TSO via MODE=TSO prefix added to the
*   command line.
* Change note: wrapped LUACMDL comments to stay in cols 1-71.
* LE bridge entry (CEEENTRY) for C runner.
*
* Change note: set PLIST=HOST for MAIN=YES to avoid MNOTE/RC=4.
* Problem: PLIST=NONE yields CEEENTRY MNOTE and ASMA90 RC=4.
* Expected effect: ASMA90 RC=0 with LE default plist handling.
* Enter LE bridge with LE-conforming prolog.
LUACMDL CEEENTRY PPA=LUCPPA,MAIN=YES,PLIST=HOST,PARMREG=1
* Establish LUACMDL code base for literals and local labels.
         BASR  R11,0           Set LUACMDL base.
LULBASE  EQU   *               LUACMDL base label.
         USING LULBASE,R11     Map LUACMDL base.
* Map LE control blocks.
         USING CEECAA,R12      Map CAA control block.
         USING CEEDSA,R13      Map DSA control block.
* Establish LUACMD base for shared storage.
         L     R10,=A(SAVE)    Load LUACMD storage anchor.
* Map LUACMD shared storage via DSECT alias.
         USING LUACMDS,R10     Map LUACMD storage alias.
* Algorithm: pass CPPL pointer to native backend via TSONCPPL.
* - Build a one-entry OS plist containing CPPL pointer value.
* - Call TSONCPPL to cache CPPL pointer in C.
* Prepare CPPL pointer for native backend.
         L     R7,CPPLPTRDS    Load CPPL pointer value.
* Change note: pass CPPL pointer value directly for OS linkage.
* Problem: extra indirection makes C read a cell, not the pointer.
* Expected effect: TSONCPPL receives CPPL pointer value.
         ST    R7,CPPLPLST     Store CPPL plist entry value.
* Call CPPL setter in native backend.
         LA    R1,CPPLPLST     Load plist address.
         L     R15,=V(TSONCPPL) Load TSONCPPL entry.
* Save LUACMDL base register across C call.
* Problem: C may clobber R11 used for LUACMDL addressability.
* Expected effect: preserve base for subsequent stores/loads.
         ST    R11,SAV11L      Save LUACMDL base.
         BALR  R14,R15         Call CPPL setter.
* Restore LUACMDL base register after C call.
         L     R11,SAV11L      Restore LUACMDL base.
* Mandatory requirement: LUAEXRUN must not default to TSO.
* LUACMD must inject MODE=TSO explicitly so mode is parameter-driven.
* Algorithm: build command line "MODE=TSO --" + operands for LUAEXRUN.
* - ARG1: LINEBUF pointer.
* - ARG2: final line length (fullword).
* - If operands exist, append a blank separator and operand text.
* - Truncate operands to keep total length <= MAXLNLEN.
* Initialize output buffer and prefix.
         LA    R6,LINEBUF      Load LINEBUF base.
* Copy MODE=TSO -- prefix into LINEBUF.
         MVC   0(PFXLEN,R6),PFXTEXT Copy prefix text.
* Seed total length with prefix length.
         LHI   R4,PFXLEN       Init total length.
* Load operand length from LUACMD storage.
         L     R5,PARMLENFWDS  Load operand length.
* Skip append when operand length is zero/negative.
         LTR   R5,R5           Test operand length.
         BNP   LINESET         Branch if length <= 0.
* Compute remaining capacity (MAX - prefix - blank).
         LHI   R8,MAXLNLEN     Load max line length.
         AHI   R8,-PFXLEN      Subtract prefix length.
         AHI   R8,-1           Reserve one blank separator.
* Skip append when no capacity remains.
         LTR   R8,R8           Test remaining capacity.
         BNP   LINESET         Branch if no capacity.
* Truncate operand length if needed.
         CR    R5,R8           Compare length to capacity.
         BNH   LENOK           Use operand length if it fits.
         LR    R5,R8           Truncate operand length.
LENOK    DS    0H              Mark length normalization.
* Add a blank separator after the prefix.
         LA    R7,LINEBUF+PFXLEN Point after prefix in LINEBUF.
         MVC   0(1,R7),=C' '   Insert separator blank.
         LA    R7,1(R7)        Advance destination past blank.
* Copy operand text into LINEBUF after the blank.
         L     R8,PARMPTRDS    Load operand text pointer.
         LR    R6,R7           Set MVCL destination address.
         LR    R7,R5           Set MVCL destination length.
         LR    R9,R5           Set MVCL source length.
         MVCL  R6,R8           Copy operand text into LINEBUF.
* Update total length with appended operand and blank.
         AR    R4,R5           Add operand length to total.
         AHI   R4,1            Add blank separator length.
LINESET  DS    0H              Mark line build complete.
* Store final line length.
         ST    R4,ARG2VAL      Store total line length.
* Change note: pass LINEBUF pointer value directly to LUAEXRUN.
* Problem: OS linkage expects pointer value, not address-of-pointer.
* Expected effect: LUAEXRUN receives LINEBUF address directly.
         LA    R7,LINEBUF      Load LINEBUF address.
         ST    R7,CALLPLST     Store LINEBUF pointer value.
* Store ARG2 cell address for by-value length argument.
         LA    R7,ARG2VAL      Load address of ARG2 cell.
         ST    R7,CALLPLST+4   Store ARG2 cell address.
* Call LUAEXRUN with constructed plist.
         LA    R1,CALLPLST     Load call plist address.
         L     R15,=V(LUAEXRUN) Load LUAEXRUN entry.
* Save LUACMDL base register across C call.
* Problem: C may clobber R11 used for LUACMDL addressability.
* Expected effect: preserve base for RETCD and literals.
         ST    R11,SAV11L      Save LUACMDL base.
         BALR  R14,R15         Call LUAEXEC runner.
* Restore LUACMDL base register after C call.
         L     R11,SAV11L      Restore LUACMDL base.
         ST    R15,RETCD       Save return code.
         L     R15,RETCD       Restore return code.
* Return to caller via LE epilog.
         CEETERM RC=(R15)      Return to caller with RC in R15.
* Place literal pool for LUACMDL.
         LTORG                Emit literal pool near LUACMDL code.
*
* LUACMDL storage and constants.
*
CALLPLST DS    2F              LUAEXRUN plist storage.
ARG2VAL  DS    F               Line length cell.
* Prefix and line buffer for LUAEXRUN command line.
PFXTEXT  DC    C'MODE=TSO --'   MODE=TSO prefix for LUAEXRUN.
PFXEND   EQU   *               End of prefix marker.
PFXLEN   EQU   PFXEND-PFXTEXT  Prefix length constant.
* Change note: shorten symbol to 8 chars for assembler naming.
* Problem: MAXLINELEN exceeds preferred 8-char naming convention.
* Expected effect: clearer naming and safer symbol handling.
MAXLNLEN EQU 511               Max LUAEXRUN line length.
LINEBUF  DS    CL512           Command line buffer.
CPPLPLST DS    F               CPPL setter plist cell.
* LUAEXRUN return code cell.
RETCD    DS    F               LUAEXRUN return code cell.
* LUACMDL base register save cell.
SAV11L   DS    F               LUACMDL base save cell.
* Define LE PPA for LUACMDL.
LUCPPA   CEEPPA                LE PPA macro.
CEECAA   DSECT                 Declare LE CAA DSECT.
* Expand LE CAA mapping macro.
         CEECAA                Expand CAA mapping.
CEEDSA   DSECT                 Declare LE DSA DSECT.
* Expand LE DSA mapping macro.
         CEEDSA                Expand DSA mapping.
* Declare CPPL DSECT anchor.
CPPL     DSECT                 Declare CPPL DSECT.
* Expand CPPL field mapping.
         IKJCPPL               Expand CPPL fields.
         END   LUACMD          End of LUACMD module.
