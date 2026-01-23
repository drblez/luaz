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
* Entry point for LUACMD CP.
LUACMD  CSECT                                 Define LUACMD control section.
* Use 31-bit addressing mode.
LUACMD  AMODE 31                              Set 31-bit addressing mode.
* Allow load above/below 16M.
LUACMD  RMODE ANY                             Allow load below/above 16M.
R0      EQU   0                               Define register 0 alias.
R1      EQU   1                               Define register 1 alias.
R2      EQU   2                               Define register 2 alias.
R3      EQU   3                               Define register 3 alias.
R4      EQU   4                               Define register 4 alias.
R5      EQU   5                               Define register 5 alias.
R6      EQU   6                               Define register 6 alias.
R7      EQU   7                               Define register 7 alias.
R8      EQU   8                               Define register 8 alias.
R9      EQU   9                               Define register 9 alias.
R10     EQU   10                              Define register 10 alias.
R11     EQU   11                              Define register 11 alias.
R12     EQU   12                              Define register 12 alias.
R13     EQU   13                              Define register 13 alias.
R14     EQU   14                              Define register 14 alias.
R15     EQU   15                              Define register 15 alias.
* External C entry for LUAEXEC runner.
         EXTRN LUAEXRUN                       Declare LUAEXRUN entry.
* External C entry for CPPL setter.
         EXTRN TSONCPPL                       Declare TSONCPPL entry.
         STM   R14,R12,12(R13)                Save caller registers.
* Load CSECT base address.
         LARL  R12,LUACMD                     Load LUACMD base into R12.
* Establish base register.
         USING LUACMD,R12                     Enable LUACMD addressability.
* Point to local save area.
         LA    R15,SAVE                       Point to local save area.
         ST    R13,4(R15)                     Back-chain save area.
         ST    R15,8(R13)                     Forward-chain save area.
* Switch to local save area.
         LR    R13,R15                        Switch to local save area.
* Save CPPL address in R10.
         LR    R10,R1                         Copy CPPL pointer from entry.
* Store CPPL pointer for LE bridge usage.
         ST    R10,CPPLPTR                    Save CPPL pointer.
         USING CPPL,R10                       Map CPPL control block.
* Point to work area.
         LA    R9,WORKAREA                    Point to work area.
         USING WORKAREA,R9                    Map work area fields.
* Load command buffer pointer.
         L     R2,CPPLCBUF                    Load CPPL command buffer pointer.
* Validate command buffer pointer.
         LTR   R2,R2                          Test command buffer pointer.
* Default to no-operand invocation.
         BZ    ONLYPFX                        Branch if no command buffer.
         LH    R3,0(R2)                       Load buffer length.
         N     R3,=X'0000FFFF'                Zero-extend length.
* Ensure header length present.
         CHI   R3,4                           Validate header length.
         BL    ONLYPFX                        Branch if header too short.
         LH    R5,2(R2)                       Load operand offset.
         N     R5,=X'0000FFFF'                Zero-extend offset.
         AHI   R3,-4                          Remove header length.
         LTR   R3,R3                          Validate text length.
         BZ    ONLYPFX                        Branch if no text.
         CR    R5,R3                          Check offset vs text length.
         BNL   ONLYPFX                        Branch if no operands.
         LA    R4,4(R2)                       Point to command text.
         AR    R4,R5                          Advance to operands.
* Compute operand length.
         SR    R3,R5                          Compute operand length.
         B     CMDREADY                       Branch with operands ready.
ONLYPFX  XC    PARMPTR,PARMPTR                Clear parm pointer.
         XC    PARMLENFW,PARMLENFW            Clear parm length.
         B     CALLLE                         Branch to LE bridge.
CMDREADY ST    R4,PARMPTR                     Store parm pointer.
         ST    R3,PARMLENFW                   Store parm length.
* Debug: CP reached before LE bridge.
CALLLE   WTO   'LUZ30047 LUACMD before LE bridge'  Emit debug before LE bridge.
* Drop CPPL/WORKAREA addressability before LE entry.
         DROP  WORKAREA                       Drop WORKAREA mapping.
         DROP  CPPL                           Drop CPPL mapping.
         SR    R1,R1                          Clear parm register for CEEENTRY.
         L     R15,=V(LUACMDL)                Load LE bridge entry.
         BALR  R14,R15                        Call LE bridge.
* Debug: returned from LE bridge.
         WTO   'LUZ30050 LUACMD after LE bridge'   Emit debug after LE bridge.
         B     EPILOG                         Branch to epilog.
* Restore save-area chain and return to caller.
EPILOG   L     R13,4(R13)                     Restore caller save area.
         LM    R14,R12,12(R13)                Restore caller registers.
         BR    R14                            Return to caller.
*
* LUACMD storage (CP entry).
*
SAVE     DS    18F                            Reserve save area storage.
WORKAREA DS    0F                             Align work area anchor.
PARMPTR  DS    F                              Operand pointer cell.
PARMLENFW DS   F                              Operand length cell.
CPPLPTR  DS    F                              CPPL pointer cell.
LEPLIST  DC    A(DUMMY)                       LE plist pointer placeholder.
DUMMY    DC    F'0'                           Dummy parameter storage.
*
* LE bridge entry (CEEENTRY) for C runner.
*
LUACMDL CEEENTRY PPA=LUCPPA,MAIN=YES,PLIST=NONE,PARMREG=1  Enter LE bridge.
* Establish LUACMDL base for local storage.
         LARL  R10,LUACMDL                    Load LUACMDL base.
         USING LUACMDL,R10                    Map LUACMDL local storage.
* Map LE control blocks.
         USING CEECAA,R12                     Map CAA control block.
         USING CEEDSA,R13                     Map DSA control block.
* Establish LUACMD base for shared storage.
         LARL  R11,LUACMD                     Load LUACMD base.
         USING LUACMD,R11                     Map LUACMD shared storage.
* Debug: LE entry reached.
         WTO   'LUZ30048 LUACMDL after CEEENTRY'   Emit debug after CEEENTRY.
* Prepare CPPL pointer for native backend.
         L     R7,CPPLPTR                     Load CPPL pointer.
         ST    R7,CPPLARG                     Store CPPL argument value.
         LA    R7,CPPLARG                     Load argument address.
         ST    R7,CPPLPLST                    Store CPPL plist entry.
* Call CPPL setter in native backend.
         WTO   'LUZ30057 LUACMDL before TSONCPPL'  Emit debug before TSONCPPL.
         LA    R1,CPPLPLST                    Load plist address.
         LARL  R15,TSONCPPL                   Load TSONCPPL entry.
         BALR  R14,R15                        Call CPPL setter.
* Debug: returned from CPPL setter.
         WTO   'LUZ30058 LUACMDL after TSONCPPL'   Emit debug after TSONCPPL.
* Build OS plist for LUAEXRUN.
         L     R7,PARMPTR                     Load line pointer.
         ST    R7,ARG1VAL                     Store line pointer value.
         L     R7,PARMLENFW                   Load line length.
         ST    R7,ARG2VAL                     Store line length value.
         L     R7,MODEPTR                     Load mode pointer.
         ST    R7,ARG3VAL                     Store mode pointer value.
         LA    R7,ARG1VAL                     Load address of arg1 cell.
         ST    R7,CALLPLST                    Store arg1 cell address.
         LA    R7,ARG2VAL                     Load address of arg2 cell.
         ST    R7,CALLPLST+4                  Store arg2 cell address.
         LA    R7,ARG3VAL                     Load address of arg3 cell.
         ST    R7,CALLPLST+8                  Store arg3 cell address.
* Debug: before calling LUAEXRUN.
         WTO   'LUZ30051 LUACMDL before LUAEXRUN'  Emit debug before LUAEXRUN.
         LA    R1,CALLPLST                    Load call plist address.
         LARL  R15,LUAEXRUN                   Load LUAEXRUN entry.
         BALR  R14,R15                        Call LUAEXEC runner.
         ST    R15,RETCD                      Save return code.
* Debug: after calling LUAEXRUN.
         WTO   'LUZ30052 LUACMDL after LUAEXRUN'   Emit debug after LUAEXRUN.
         L     R15,RETCD                      Restore return code.
         CEETERM RC=(R15)                     Return to caller via LE epilog.
*
* LUACMDL storage and constants.
*
CALLPLST DS    3F                             LUAEXRUN plist storage.
ARG1VAL  DS    F                              Line pointer cell.
ARG2VAL  DS    F                              Line length cell.
ARG3VAL  DS    F                              Mode pointer cell.
CPPLPLST DS    F                              CPPL setter plist cell.
CPPLARG  DS    F                              CPPL pointer value cell.
RETCD    DS    F                              LUAEXRUN return code cell.
MODEPTR  DC    A(MODETSO)                     MODE pointer cell.
MODETSO  DC    C'TSO',X'00'                   MODE=TSO literal value.
LUCPPA   CEEPPA                               Define LE PPA for LUACMDL.
CEECAA   DSECT                                Declare LE CAA DSECT.
         CEECAA                               Expand LE CAA mapping macro.
CEEDSA   DSECT                                Declare LE DSA DSECT.
         CEEDSA                               Expand LE DSA mapping macro.
CPPL     DSECT                                Declare CPPL DSECT anchor.
         IKJCPPL                              Expand CPPL field mapping.
         END   LUACMD                         End of LUACMD module.
