//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Lua integration test for tso module via LUAEXEC runner.
//* Objects:
//* +---------+----------------------------------------------+
//* | RUN     | Execute ITTSO Lua script                     |
//* +---------+----------------------------------------------+
//ITTSO  JOB (ACCT),'IT TSO',CLASS=A,MSGCLASS=H,NOTIFY=&SYSUID,
//             MSGLEVEL=(1,1),REGION=0M
//SET1     SET HLQ=DRBLEZ
//* Run integration test script
//RUN     EXEC PGM=IKJEFT01
//* Change: remove STEPLIB for TSO command processor runs.
//* Problem: STEPLIB is unnecessary when LUACMD/LUAEXEC are in LNKLST.
//* Expected effect: TSO resolves command processor from LNKLST only.
//* Impact: simplifies job and ensures consistent load module source.
//SYSTSPRT DD SYSOUT=*
//* Change: add SNAP DD for SNAPX diagnostics.
//* Problem: SNAPX needs an output DD distinct from SYSABEND/SYSUDUMP.
//* Expected effect: SNAPX output is written to SYSOUT for analysis.
//* Impact: additional spool file with targeted dump output.
//SNAP    DD SYSOUT=*
//CEEDUMP DD SYSOUT=*
//* Change: ensure CEEOPTS/SNAP DD are allocated outside SYSTSIN data.
//* Problem: DD statements inside in-stream data are treated as commands.
//* Expected effect: SNAP/CEEOPTS are allocated as proper DDs.
//* Impact: SNAPX and CEEDUMP output now appear in spool.
//* Change: drop SYSUDUMP while using SNAPX diagnostics.
//* Problem: SYSUDUMP is large and skipped by fetch script.
//* Expected effect: SNAPX output lands in DD SNAP only.
//* Impact: no SYSUDUMP allocation for this job.
//* Change: enable SYSUDUMP to locate the failing PSW before SNAP.
//* Problem: ABEND 4088/63 occurs before SNAPX; need dump to place SNAP.
//* Expected effect: SYSUDUMP shows failing module/offset and registers.
//* Impact: additional SYSUDUMP spool file for analysis.
//* Change: enable LE TRACE and force CEEDUMP (no SYSMDUMP).
//* Problem: TERMTHDACT(DUMP) attempts IEATDUMP and can skip CEEDUMP.
//* Expected effect: CEEDUMP includes LE trace table and traceback.
//* Impact: CEEDUMP appears in spool with TRACE data for analysis.
//* See: jcl/ITTSO.md#ceeopts-trace
//SYSUDUMP DD SYSOUT=*
//CEEOPTS DD *
  RPTOPTS(ON),
  RPTSTG(ON),
  TRAP(ON,SPIE),
  ABTERMENC(ABEND),
  TERMTHDACT(DUMP),
  TRACE(ON,256K,DUMP,LE=1)
/*
//LUAIN   DD DSN=&HLQ..LUA.TEST(ITTSO),DISP=SHR
//* Change: provide REXX exec library for capture=true OUTTRAP path.
//* Problem: tso.cmd(..., true) calls LUTSO via IRXEXEC.
//* Expected effect: LUTSO is found under SYSEXEC for command capture.
//* Impact: SYSEXEC points to HLQ.LUA.REXX in this job.
//SYSEXEC DD DSN=&HLQ..LUA.REXX,DISP=SHR
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//* Change: add TSOLIB ACTIVATE to place LOADLIB at top of search order.
//* Problem: LUACMD not found as AUTHCMD in batch without explicit task lib.
//* Expected effect: TSO/E resolves LUACMD from DRBLEZ.LUA.LOADLIB.
//* Impact: search order is modified for this TMP session only.
//* Note: Quote DSNAME to avoid TSO prefixing (e.g., DRBLEZ.DRBLEZ...).
//SYSTSIN  DD *
  TSOLIB ACTIVATE DSNAME('DRBLEZ.LUA.LOADLIB')
  TSOLIB DISPLAY
  LUACMD LUZTRACE ARG1 'ARG TWO'
/*
//*
