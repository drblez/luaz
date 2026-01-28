* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
*
* LUACMD -- TSO command processor wrapper for LUAEXEC.
*
* Object Table:
* | Object | Kind | Purpose |
* |--------|------|---------|
* | LUACMD | CSECT | Parse CPPL and drive CEEPIPI preinit |
* | TR_* | storage | Trace cells for preinit stages |
* | PPTBL | table | PreInit table for TSONCPPL/LUAEXRUN |
*
* User Actions:
* - Link with AC=1 into APF-authorized library if required by site
* policy.
* - Add LUACMD to AUTHPGM/AUTHTSF and AUTHCMD in IKJTSO00.
* - Run under IKJEFT01 (TMP) for SYSTSPRT output.
*
* Platform Requirements:
* - LE: required (CEEPIPI preinit interface).
* - AMODE: 31-bit (TSO command processors).
* - EBCDIC: command buffer and literals.
* - DDNAME I/O: relies on SYSTSPRT for output.
*
* Entry point: LUACMD (TSO command processor).
* - Purpose: parse CPPL command buffer and dispatch to CEEPIPI
* preinitialization calls.
* - Input: R1 points to CPPL control block; CPPLCBUF contains
* length/offset.
* - Output: R15 return code propagated from LUAEXRUN (typically 0/8).
* - Special cases: no operands or short buffer -> pass empty line
* pointer with zero length.
* - Notes: LUACMD is non-LE; it uses CEEPIPI to create an LE
*   environment and call LUAEXRUN.
* Change note: wrapped comments to keep columns 1-71 and avoid
* ASMA144E continuations; no functional behavior change.
* Define LUACMD control section.
LUACMD   CSECT
* Set 31-bit addressing mode.
LUACMD   AMODE 31
* Allow load above/below 16M.
LUACMD   RMODE ANY
R0       EQU   0                              Reg0 alias.
R1       EQU   1                              Reg1 alias.
R2       EQU   2                              Reg2 alias.
R3       EQU   3                              Reg3 alias.
R4       EQU   4                              Reg4 alias.
R5       EQU   5                              Reg5 alias.
R6       EQU   6                              Reg6 alias.
R7       EQU   7                              Reg7 alias.
R8       EQU   8                              Reg8 alias.
R9       EQU   9                              Reg9 alias.
* Define register 10 alias.
R10      EQU   10                             Reg10 alias.
* Define register 11 alias.
R11      EQU   11                             Reg11 alias.
* Define register 12 alias.
R12      EQU   12                             Reg12 alias.
* Define register 13 alias.
R13      EQU   13                             Reg13 alias.
* Define register 14 alias.
R14      EQU   14                             Reg14 alias.
* Define register 15 alias.
R15      EQU   15                             Reg15 alias.
* External C entry for LUAEXEC runner.
         EXTRN LUAEXRUN                       Declare LUAEXRUN entry.
* External C entry for CPPL setter.
         EXTRN TSONCPPL                       Declare TSONCPPL entry.
* Save caller registers.
         STM   R14,R12,12(R13)                Save caller regs.
* Establish LUACMD base register for addressability.
         BALR  R12,0                          Set base register.
* Define LUACMD base alias to avoid overlapping USING.
LUCBASE  EQU   *                              Base label for LUACMD.
         USING LUCBASE,R12                    Map LUACMD base.
* Change note: preserve LUACMD base across macros.
* Problem: OPEN/LOAD may clobber R12, breaking base addressing.
* Expected effect: LINEBUF/label addresses resolve from stable base.
* Impact: fixes incorrect LINEPTRV values and LUAEXRUN input.
         ST    R12,BASER12             Save LUACMD base register value.
* Change note: remove early ABEND used for LUACMD identity test.
* Problem: forced ABEND prevents CPPL parsing and LUAEXRUN call.
* Expected effect: normal LUACMD flow resumes for CPPL/LUAEXRUN flow.
* Impact: LUACMD continues into preinit and call_sub logic.
* Point to local save area.
         LA    R15,SAVE                       Load local save area.
         ST    R13,4(R15)                     Back-chain save area.
         ST    R15,8(R13)                     Forward-chain save area.
* Switch to local save area.
         LR    R13,R15                        Activate local save area.
* Save CPPL address in R10.
         LR    R10,R1                         Copy CPPL pointer.
* Store CPPL pointer for preinit calls.
         ST    R10,CPPLPTR                    Save CPPL pointer.
         USING CPPL,R10                       Map CPPL control block.
* Algorithm: parse CPPL command buffer to derive operand
* pointer/length.
* - If CPPLCBUF is NULL or too short, clear PARMPTR/PARMLENFW.
* - Otherwise compute operand pointer/length from header fields.
* Load CPPL command buffer pointer.
         L     R2,CPPLCBUF                    Load CPPL command buffer.
* Validate command buffer pointer.
         LTR   R2,R2                       Test command buffer pointer.
* Default to no-operand invocation.
         BZ    ONLYPFX                     Branch if no command buffer.
         LH    R3,0(R2)                       Load buffer length.
         N     R3,=X'0000FFFF'                Zero-extend length.
* Ensure header length present.
         CHI   R3,4                           Validate header length.
* Branch if header too short.
         BL    ONLYPFX                        Branch if too short.
         LH    R5,2(R2)                       Load operand offset.
         N     R5,=X'0000FFFF'                Zero-extend offset.
         AHI   R3,-4                          Remove header length.
         LTR   R3,R3                          Validate text length.
         BZ    ONLYPFX                        Branch if no text.
* Check offset vs text length.
         CR    R5,R3                          Compare offset to length.
         BNL   ONLYPFX                        Branch if no operands.
         LA    R4,4(R2)                       Point to command text.
         AR    R4,R5                          Advance to operands.
* Compute operand length.
         SR    R3,R5                          Compute operand length.
* Branch with operands ready.
         B     CMDREADY                       Branch to CMDREADY.
ONLYPFX  LA    R4,EMPTYCMD                    Load empty line address.
         ST    R4,PARMPTR                     Store empty line pointer.
         XC    PARMLENFW,PARMLENFW            Clear parm length.
         B     CMDTRACE                       Branch to trace stage.
CMDREADY ST    R4,PARMPTR                     Store parm pointer.
         ST    R3,PARMLENFW                   Store parm length.
CMDTRACE DS    0H                             Trace parsed operands.
* Trace: record operand pointer/length from CPPL parse.
         MVC   TR_PARSE_STAGE,TRC_PARSE       Set trace stage value.
         MVC   TR_PARSE_PARMPTR,PARMPTR      Save operand pointer cell.
         MVC   TR_PARSE_PARMLEN,PARMLENFW     Save operand length cell.
         MVC   TR_PARSE_CPPL,CPPLPTR          Save CPPL pointer cell.
* Change note: remove LUZTRACE operand parsing.
* Problem: debug prefix handling may alter operands before LUAEXRUN.
* Expected effect: operands are passed unchanged to LUAEXRUN.
* Impact: no conditional LUZTRACE-driven behavior in LUACMD.
* Algorithm: build LUAEXRUN command line and invoke via CEEPIPI.
* - Build MODE=TSO -- line from CPPL operands.
* - Prepare OS plists for TSONCPPL and LUAEXRUN.
* - Use CEEPIPI init_sub/call_sub/term from non-LE CP.
* Ref: src/luacmd.md#ceepipi-preinit
PIPI_DRV DS    0H                           Preinit driver entry point.
* Drop CPPL mapping before preinit work.
         DROP  CPPL                           Drop CPPL DSECT mapping.
* Mandatory requirement: LUAEXRUN must not default to TSO.
* LUACMD must inject MODE=TSO explicitly so mode is parameter-driven.
* Algorithm: build command line "MODE=TSO --" + operands.
* - ARG1: LINEBUF pointer (by value via OS plist).
* - ARG2: final line length (fullword).
* - If operands exist, append a blank separator and operand text.
* - Truncate operands to keep total length <= MAXLNLEN.
* Initialize output buffer and prefix.
         LA    R6,LINEBUF                     Load LINEBUF base.
* Copy MODE=TSO -- prefix into LINEBUF.
         MVC   0(PFXLEN,R6),PFXTEXT           Copy prefix text.
* Seed total length with prefix length.
         LHI   R4,PFXLEN                      Init total length.
* Load operand length from LUACMD storage.
         L     R5,PARMLENFW                   Load operand length.
* Skip append when operand length is zero/negative.
         LTR   R5,R5                          Test operand length.
         BNP   LINESET                        Branch if length <= 0.
* Compute remaining capacity (MAX - prefix - blank).
         LHI   R8,MAXLNLEN                    Load max line length.
         AHI   R8,-PFXLEN                     Subtract prefix length.
         AHI   R8,-1                       Reserve one blank separator.
* Skip append when no capacity remains.
         LTR   R8,R8                          Test remaining capacity.
         BNP   LINESET                        Branch if no capacity.
* Truncate operand length if needed.
         CR    R5,R8                        Compare length to capacity.
         BNH   LENOK                     Use operand length if it fits.
         LR    R5,R8                          Truncate operand length.
LENOK    DS    0H                            Mark length normalization.
* Add a blank separator after the prefix.
         LA    R7,LINEBUF+PFXLEN         Point after prefix in LINEBUF.
         MVC   0(1,R7),=C' '                  Insert separator blank.
         LA    R7,1(R7)                 Advance destination past blank.
* Copy operand text into LINEBUF after the blank.
         L     R8,PARMPTR                    Load operand text pointer.
         LR    R6,R7                      Set MVCL destination address.
         LR    R7,R5                       Set MVCL destination length.
         LR    R9,R5                          Set MVCL source length.
         MVCL  R6,R8                    Copy operand text into LINEBUF.
* Update total length with appended operand and blank.
         AR    R4,R5                       Add operand length to total.
         AHI   R4,1                         Add blank separator length.
LINESET  DS    0H                             Mark line build complete.
* Store LINEBUF pointer value in cell for OS plist.
         LA    R7,LINEBUF                     Load LINEBUF address.
         ST    R7,LINEPTRV                  Store LINEBUF pointer cell.
* Store final line length in cell for OS plist.
         ST    R4,LINELENV                    Store line length cell.
* Change note: build OS plist with address/value semantics per IBM.
* Problem: OS-linkage address parameters require the address value in
* the plist, not the address of a pointer cell; value parameters use
* the address of their copy. Incorrect plist yields empty line in C.
* Expected effect: LUAEXRUN receives correct line pointer and length.
* Impact: LUAZ_MODE parsing uses MODE=TSO line content as expected.
* Ref: src/luacmd.md#os-linkage-plist
* Build LUAEXRUN plist[0] with direct LINEBUF address (address param).
         L     R7,LINEPTRV        Load LINEBUF pointer value for plist.
         ST    R7,LUALIST0           Store address value into plist[0].
* Build LUAEXRUN plist[1] with address of length cell (value param).
         LA    R7,LINELENV          Load length cell address for plist.
         ST    R7,LUALIST1     Store length cell address into plist[1].
* Change note: pass CPPL to LUAEXRUN for native TSO use in LUAEXE.
* Problem: LUAEXE cannot see LUACMD globals, so CPPL must be passed.
* Expected effect: LUAEXRUN caches CPPL locally and native TSO works.
* Impact: tso.cmd uses LUACMD-provided CPPL without IKJTSOEV.
* Ref: src/luacmd.md#os-linkage-plist
* Load CPPL pointer value for LUAEXRUN plist.
         L     R7,CPPLPTR            Load CPPL pointer value for plist.
* Mask CPPL pointer to 31-bit for OS linkage.
         NILF  R7,X'7FFFFFFF'      Mask CPPL pointer to 31-bit address.
* Mark plist end on the CPPL entry.
         OILF  R7,X'80000000'              Set HOB on last plist entry.
* Store CPPL pointer into LUAEXRUN plist[2].
         ST    R7,LUALIST2            Store CPPL address into plist[2].
* Trace: record LINEBUF pointer and length.
         MVC   TR_LINE_STAGE,TRC_LINE         Set trace stage value.
         MVC   TR_LINE_PTR,LINEPTRV          Save LINEBUF pointer cell.
         MVC   TR_LINE_LEN,LINELENV           Save LINEBUF length cell.
* Change note: use static OS plist for LUAEXRUN argument cells.
* Problem: dynamic LUALIST stores self-referential addresses, so C
* sees the cell address instead of the LINEBUF pointer value.
* Expected effect: LUAEXRUN receives OS linkage addresses of LINEPTRV
* and LINELENV, so C gets the correct LINEBUF pointer and length.
* Impact: fixes LUAZ_MODE parsing by delivering MODE=TSO line content.
* Load CEEPIPI service routine for preinit calls.
* Problem: direct CEEENTRY MAIN=YES from non-LE CP breaks DSA.
* Expected effect: CEEPIPI builds LE enclave for call_sub.
* Ref: src/luacmd.md#ceepipi-preinit
         LOAD  EP=CEEPIPI                     Load CEEPIPI routine.
* Change note: restore LUACMD base after LOAD macro.
* Problem: LOAD can clobber R12, shifting stores into CPPLLIST.
* Expected effect: PPRTNPTR and CPPLLIST remain distinct and correct.
* Impact: TSONCPPL receives the CPPL pointer; LUAEXEC sees CPPL.
         L     R12,BASER12                Restore LUACMD base register.
         USING LUCBASE,R12                Reassert LUACMD base mapping.
* Save CEEPIPI entry address for subsequent calls.
         ST    R0,PPRTNPTR                  Save CEEPIPI entry address.
* Trace: record CEEPIPI entry address after LOAD.
         MVC   TR_LOAD_STAGE,TRC_LOAD         Set trace stage value.
         MVC   TR_LOAD_ADDR,PPRTNPTR        Save CEEPIPI entry address.
* Validate CEEPIPI entry address.
         LTR   R0,R0                        Test CEEPIPI entry address.
         BZ    PIPI_FAIL_LOAD                 Branch on LOAD failure.
* Initialize preinit subroutine environment.
* Prepare PreInit table address for init_sub.
         LA    R7,PPTBL                     Load PreInit table address.
         ST    R7,PCTBLAD                  Store PreInit table pointer.
* Call CEEPIPI init_sub with OS plist.
         LA    R1,PINITLST                 Load init_sub plist address.
         L     R15,PPRTNPTR                 Load CEEPIPI entry address.
         BALR  R14,R15                        Call init_sub service.
* Trace: record init_sub return and token.
         MVC   TR_INIT_STAGE,TRC_INIT         Set trace stage value.
         ST    R15,TR_INIT_RC                 Save init_sub RC.
         MVC   TR_INIT_TOKEN,PTOKEN           Save init_sub token.
* Test init_sub return code.
         LTR   R15,R15                        Test init_sub RC in R15.
         BNZ   PIPI_FAIL_INIT               Branch on init_sub failure.
* Change note: rebuild CPPL plist immediately before TSONCPPL call.
* Problem: earlier CPPLVAL/CPPLLIST may be overwritten by
* LOAD/init_sub.
* Expected effect: TSONCPPL receives a fresh CPPL pointer cell address.
* Impact: tso_native_set_cppl sees a valid CPPL pointer value.
* Build TSONCPPL OS plist using CPPL pointer cell address.
* Problem: TSONCPPL received a truncated CPPL value in C.
* Expected effect: pass address of CPPL value cell with HOB set.
* Impact: tso_native_set_cppl sees full 31-bit CPPL pointer.
* Ref: src/luacmd.md#os-linkage-plist
         L     R7,CPPLPTR                     Load CPPL pointer value.
         NILF  R7,X'7FFFFFFF'      Mask CPPL pointer to 31-bit address.
         ST    R7,CPPLVAL                     Store CPPL pointer cell.
         LA    R7,CPPLVAL               Load CPPL pointer cell address.
         OILF  R7,X'80000000'              Mark last plist entry (HOB).
         ST    R7,CPPLLIST       Store CPPL plist entry (cell address).
* Call TSONCPPL to cache CPPL inside LE.
         LHI   R7,0                    Load PreInit index for TSONCPPL.
         ST    R7,PPTBIDX                    Store PreInit table index.
         LA    R7,CPPLLIST                    Load CPPL plist address.
         ST    R7,PPARMP                   Store parm_ptr for call_sub.
         LA    R1,PCALLLST                 Load call_sub plist address.
         L     R15,PPRTNPTR                 Load CEEPIPI entry address.
         BALR  R14,R15                        Call call_sub (TSONCPPL).
* Trace: record call_sub RC and TSONCPPL outputs.
         MVC   TR_CPPL_STAGE,TRC_CPPL         Set trace stage value.
         ST    R15,TR_CPPL_RC              Save call_sub RC (TSONCPPL).
         MVC   TR_CPPL_SUBRET,PSUBRET         Save sub return code.
         MVC   TR_CPPL_SUBRSN,PSUBRSN         Save sub reason code.
         LTR   R15,R15                        Test call_sub RC in R15.
         BNZ   PIPI_FAIL_CALL               Branch on call_sub failure.
* Call LUAEXRUN with constructed line plist.
         LHI   R7,1                    Load PreInit index for LUAEXRUN.
         ST    R7,PPTBIDX                    Store PreInit table index.
         LA    R7,LUALIST                  Load LUAEXRUN plist address.
         ST    R7,PPARMP                   Store parm_ptr for call_sub.
         LA    R1,PCALLLST                 Load call_sub plist address.
         L     R15,PPRTNPTR                 Load CEEPIPI entry address.
* Change note: remove SNAPX pre-call diagnostics.
* Problem: SNAPX diagnostics are no longer required and add DD
* dependencies for LUACMD execution.
* Expected effect: LUAEXRUN call_sub runs without SNAP DD.
* Impact: LUACMD no longer abends when SNAP is not allocated.
         BALR  R14,R15                        Call call_sub (LUAEXRUN).
* Trace: record call_sub RC and LUAEXRUN outputs.
         MVC   TR_RUN_STAGE,TRC_RUN           Set trace stage value.
         ST    R15,TR_RUN_RC               Save call_sub RC (LUAEXRUN).
         MVC   TR_RUN_SUBRET,PSUBRET          Save sub return code.
         MVC   TR_RUN_SUBRSN,PSUBRSN          Save sub reason code.
         LTR   R15,R15                        Test call_sub RC in R15.
         BNZ   PIPI_FAIL_CALL               Branch on call_sub failure.
* Save LUAEXRUN return code from call_sub.
         L     R15,PSUBRET                   Load LUAEXRUN return code.
         ST    R15,RCMD                       Save final RC for caller.
* Terminate preinitialized LE environment.
         LA    R1,PTERMLST                    Load term plist address.
         L     R15,PPRTNPTR                 Load CEEPIPI entry address.
         BALR  R14,R15                        Call term service.
* Trace: record term RC and env RC.
         MVC   TR_TERM_STAGE,TRC_TERM         Set trace stage value.
         ST    R15,TR_TERM_RC                 Save term RC.
         MVC   TR_TERM_ENVRC,PENVRC           Save environment RC.
         LTR   R15,R15                        Test term RC in R15.
         BNZ   PIPI_FAIL_TERM                 Branch on term failure.
* Change note: return directly after term with no SNAPX dependency.
* Problem: SNAPX diagnostics were removed from LUACMD.
* Expected effect: return path is clean and has no SNAP DD dependency.
         B     EPILOG                         Fallback return path.
* Change note: failure paths return directly without SNAPX.
* Problem: diagnostic SNAPX paths are no longer present.
* Expected effect: failures return RC directly with no SNAP activity.
* Failure: CEEPIPI LOAD failed.
PIPI_FAIL_LOAD DS 0H                         Mark CEEPIPI load failure.
         LHI   R15,12                      Load RC for preinit failure.
         ST    R15,RCMD                       Store RC for caller.
         B     EPILOG                         Return to caller.
* Failure: init_sub failed.
PIPI_FAIL_INIT DS 0H                          Mark init_sub failure.
         LHI   R15,12                     Load RC for init_sub failure.
         ST    R15,RCMD                       Store RC for caller.
         B     EPILOG                         Return to caller.
* Failure: call_sub failed.
PIPI_FAIL_CALL DS 0H                          Mark call_sub failure.
         LHI   R15,12                     Load RC for call_sub failure.
         ST    R15,RCMD                       Store RC for caller.
         B     EPILOG                         Return to caller.
* Failure: term failed.
PIPI_FAIL_TERM DS 0H                          Mark term failure.
         LHI   R15,12                         Load RC for term failure.
         ST    R15,RCMD                       Store RC for caller.
         B     EPILOG                         Return to caller.
* Restore save-area chain and return to caller.
EPILOG   L     R13,4(R13)                     Restore caller save area.
         LM    R14,R12,12(R13)                Restore caller registers.
* Change note: restore CPPL in R1 after LM clobbers it.
* Problem: LM restores R1 from save area, not CPPL.
* Expected effect: TMP sees CPPL in R1 on return.
         L     R1,CPPLPTR                   Restore CPPL pointer in R1.
* Change note: restore RC in R15 after LM clobbers it.
* Problem: LM restores stale R15 from save area.
* Expected effect: LUACMD returns correct RC to TMP.
         L     R15,RCMD                       Restore final RC in R15.
* Trace: record final RC returned to TMP.
         MVC   TR_EXIT_STAGE,TRC_EXIT         Set trace stage value.
         ST    R15,TR_EXIT_RC                 Save final RC.
         BR    R14                            Return to caller.
*
* Place literal pool before LUACMD storage to keep literals
* addressable for LUACMD code and macros.
         LTORG Emit                      literal pool near LUACMD code.
* LUACMD storage (CP entry and preinit driver).
*
* Reserve save area storage.
SAVE     DS    18F                            Save area storage.
WORKAREA DS    0F                             Align work area anchor.
TRC_DUMP_START EQU *                          Trace dump block start.
PARMPTR   DS   F                              Operand pointer cell.
PARMLENFW DS   F                              Operand length cell.
CPPLPTR   DS   F                              CPPL pointer cell.
RCMD      DS   F                           Return code cell for LUACMD.
EMPTYCMD DC    X'00'                          Empty line buffer.
* Saved LUACMD base register (R12).
BASER12  DS    F                       Base register preservation cell.
* Trace storage for LUACMD stages.
TR_PARSE_STAGE   DS F                     Trace stage: parsed operands.
TR_PARSE_PARMPTR DS F                         Trace operand pointer.
TR_PARSE_PARMLEN DS F                         Trace operand length.
TR_PARSE_CPPL    DS F                         Trace CPPL pointer.
TR_LINE_STAGE    DS F                         Trace stage: line built.
TR_LINE_PTR      DS F                         Trace LINEBUF pointer.
TR_LINE_LEN      DS F                         Trace LINEBUF length.
TR_LOAD_STAGE    DS F                        Trace stage: CEEPIPI LOAD.
TR_LOAD_ADDR     DS F                      Trace CEEPIPI entry address.
TR_INIT_STAGE    DS F                         Trace stage: init_sub.
TR_INIT_RC       DS F                         Trace init_sub RC.
TR_INIT_TOKEN    DS F                         Trace init_sub token.
TR_CPPL_STAGE    DS F                   Trace stage: call_sub TSONCPPL.
TR_CPPL_RC       DS F                     Trace call_sub RC (TSONCPPL).
TR_CPPL_SUBRET   DS F                      Trace sub return (TSONCPPL).
TR_CPPL_SUBRSN   DS F                      Trace sub reason (TSONCPPL).
TR_RUN_STAGE     DS F                   Trace stage: call_sub LUAEXRUN.
TR_RUN_RC        DS F                     Trace call_sub RC (LUAEXRUN).
TR_RUN_SUBRET    DS F                      Trace sub return (LUAEXRUN).
TR_RUN_SUBRSN    DS F                      Trace sub reason (LUAEXRUN).
TR_TERM_STAGE    DS F                         Trace stage: term.
TR_TERM_RC       DS F                         Trace term RC.
TR_TERM_ENVRC    DS F                         Trace environment RC.
TR_EXIT_STAGE    DS F                         Trace stage: exit.
TR_EXIT_RC       DS F                         Trace final RC.
* Trace stage constants.
TRC_PARSE DC   F'1'                     Trace stage id: parse complete.
TRC_LINE  DC   F'2'                         Trace stage id: line built.
TRC_LOAD  DC   F'3'                     Trace stage id: CEEPIPI loaded.
TRC_INIT  DC   F'4'                      Trace stage id: init_sub done.
TRC_CPPL  DC   F'5'                      Trace stage id: TSONCPPL done.
TRC_RUN   DC   F'6'                      Trace stage id: LUAEXRUN done.
TRC_TERM  DC   F'7'                          Trace stage id: term done.
TRC_EXIT  DC   F'8'                           Trace stage id: exit.
TRC_DUMP_END EQU *-1                          Trace dump block end.
* LUAEXRUN line argument cells.
LINEPTRV DS    F                            LINEBUF pointer value cell.
LINELENV DS    F                             LINEBUF length value cell.
LUALIST  DS    0F                      LUAEXRUN plist base (3 entries).
LUALIST0 DS    F                 LUAEXRUN plist entry 0 (line address).
LUALIST1 DS    F                LUAEXRUN plist entry 1 (len cell addr).
LUALIST2 DS    F                 LUAEXRUN plist entry 2 (CPPL address).
* TSONCPPL argument cells.
CPPLVAL  DS    F                              CPPL pointer value cell.
CPPLLIST DS    F                           TSONCPPL OS plist (1 entry).
* CEEPIPI entry address storage.
PPRTNPTR DS    A                            CEEPIPI entry address cell.
PIPI_DUMP_START EQU *                         Preinit dump block start.
* Parameters passed to init_sub (CEEPIPI function 3).
PINITFC  DC    F'3'                           init_sub function code.
PCTBLAD  DS    A                            PreInit table pointer cell.
PSRVRTN  DC    A(0)                      Service routine vector (none).
* Change note: supply explicit LE runtime options for CEEPIPI.
* Problem: CEEDUMP/condition data may be suppressed during ABEND
* inside LE.
* Expected effect: LE uses TERMTHDACT(UADUMP) and TRAP(ON,SPIE) to
* emit CEEDUMP/trace data on abnormal termination.
* Impact: LUACMD preinit uses these options for the LE enclave.
* Ref: src/luacmd.asm.md#cee-runtime-options
PRTMOPT  DC    CL255'TRAP(ON,SPIE),TERMTHDACT(UADUMP),RPTOPTS(ON)'
PTOKEN   DS    F                             Preinit environment token.
* Parameters passed to call_sub (CEEPIPI function 4).
PCALLFC  DC    F'4'                           call_sub function code.
PPTBIDX  DS    F                              PreInit table index cell.
PPARMP   DS    A                              Parm list pointer cell.
PSUBRET  DS    F                           Subroutine return code cell.
PSUBRSN  DS    F                           Subroutine reason code cell.
PSUBFBC  DS    3F                        Subroutine feedback code cell.
PIPI_DUMP_END EQU *-1                         Preinit dump block end.
* Parameters passed to term (CEEPIPI function 5).
PTERMFC  DC    F'5'                           term function code.
PENVRC   DS    F                          Environment return code cell.
* OS plists for CEEPIPI calls (list of parameter addresses).
PINITLST DC    A(PINITFC)                init_sub plist: function code.
         DC    A(PCTBLAD)            init_sub plist: PreInit table ptr.
         DC    A(PSRVRTN)               init_sub plist: service vector.
         DC    A(PRTMOPT)                 init_sub plist: runtime opts.
         DC    A(PTOKEN)                  init_sub plist: token output.
PCALLLST DC    A(PCALLFC)                call_sub plist: function code.
         DC    A(PPTBIDX)                  call_sub plist: table index.
         DC    A(PTOKEN)                      call_sub plist: token.
         DC    A(PPARMP)                      call_sub plist: parm_ptr.
         DC    A(PSUBRET)                 call_sub plist: sub ret code.
         DC    A(PSUBRSN)              call_sub plist: sub reason code.
         DC    A(PSUBFBC)            call_sub plist: sub feedback code.
PTERMLST DC    A(PTERMFC)                    term plist: function code.
         DC    A(PTOKEN)                      term plist: token.
         DC    A(PENVRC)                   term plist: env return code.
* Prefix and line buffer for LUAEXRUN command line.
PFXTEXT  DC    C'MODE=TSO --'             MODE=TSO prefix for LUAEXRUN.
PFXEND   EQU   *                              End of prefix marker.
PFXLEN   EQU   PFXEND-PFXTEXT                 Prefix length constant.
* Change note: shorten symbol to 8 chars for assembler naming.
* Problem: MAXLINELEN exceeds preferred 8-char naming convention.
* Expected effect: clearer naming and safer symbol handling.
MAXLNLEN EQU   511                            Max LUAEXRUN line length.
LINEBUF  DS    CL512                          Command line buffer.
LBUFEND  EQU   *-1                            End of LINEBUF range.
* Change note: force PreInit entry_point addresses with AMODE31 bit.
* Problem: CEEXPITY name,0 triggers dynamic LOAD of separate modules.
* Expected effect: CEEPIPI uses in-module entry addresses for calls.
* Impact: init_sub resolves table entries without external LOAD.
* Ref: src/luacmd.md#ceexpity-entry-point
AMODE31B EQU   X'80000000'                 AMODE31 high-order-bit flag.
* PreInit table for CEEPIPI (TSONCPPL, LUAEXRUN).
PPTBL    CEEXPIT Begin                        PreInit table (indexed).
         CEEXPITY TSONCPPL,TSONCPPL+AMODE31B  Entry addr with AMODE31.
         CEEXPITY LUAEXRUN,LUAEXRUN+AMODE31B  Entry addr with AMODE31.
         CEEXPITS End                         PreInit table.
* PreInit table end marker.
PPTBL_END EQU  *-1                            End of PreInit table.
* Declare CPPL DSECT anchor.
CPPL     DSECT Declare                        CPPL DSECT.
* Expand CPPL field mapping.
         IKJCPPL Expand                       CPPL fields.
         END   LUACMD                         End of LUACMD module.
