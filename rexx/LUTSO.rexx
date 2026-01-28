/* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO REXX bridge for TSO command execution.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | LUTSO  | REXX exec | Execute TSO commands and optional output capture |
 */
parse upper arg packed
/* Change note: accept packed args mode|outdd|payload from IRXEXEC.
 * Problem: multi-arg IRXEXEC parmlist passed only the first argument.
 * Expected effect: mode/outdd/payload are always parsed consistently.
 * Impact: tso.cmd capture path passes a single packed argument.
 * Ref: rexx/LUTSO.rexx.md#outtrap-systsprt
 */
parse var packed mode '|' outdd '|' payload

mode = strip(mode)
outdd = strip(outdd)
rc = 0

select
  when mode = "CMD" then do
    if outdd <> "" then do
      if outdd = "TSOOUT" then do
        /* Change note: allocate temporary output DD for EXECIO capture. */
        /* Problem: SYSOUT-backed SYSTSPRT cannot be read inside the step. */
        /* Expected effect: use a temp dataset DD for C to read immediately. */
        /* Impact: tso.cmd capture reads TSOOUT and C frees it after read. */
        /* Ref: rexx/LUTSO.rexx.md#alloc-free */
        uid = sysvar("SYSUID")
        out_dsn = uid || ".LUAZ.TSOOUT"
        address TSO "DELETE '" || out_dsn || "'"
        alloc_cmd = "ALLOCATE DDNAME(TSOOUT) DSNAME('" || out_dsn || "') NEW "
        alloc_cmd = alloc_cmd || "UNIT(SYSDA) SPACE(5,5) TRACKS "
        alloc_cmd = alloc_cmd || "RECFM(V,B) LRECL(1024) BLKSIZE(0) CATALOG"
        address TSO alloc_cmd
        if RC <> 0 then do
          rc = RC
          return rc
        end
      end
      call outtrap "LUZOUT."
      address TSO payload
      rc = RC
      call outtrap "OFF"
      if outdd = "SYSTSPRT" then do
        /* Change note: emit trapped output to SYSTSPRT for capture=true. */
        /* Problem: Lua capture path should avoid DD routing and ASM use. */
        /* Expected effect: OUTTRAP lines are written to SYSTSPRT via SAY. */
        /* Impact: C can read SYSTSPRT and return command output lines. */
        /* Ref: rexx/LUTSO.rexx.md#outtrap-systsprt */
        do i = 1 to LUZOUT.0
          say LUZOUT.i
        end
      end
      else do
        if LUZOUT.0 = 0 then do
          LUZOUT.0 = 1
          LUZOUT.1 = ""
        end
        "EXECIO" LUZOUT.0 "DISKW" outdd "(STEM LUZOUT. FINIS"
      end
    end
    else do
      address TSO payload
      rc = RC
    end
  end
  when mode = "ALLOC" then do
    address TSO "ALLOCATE" payload
    rc = RC
  end
  when mode = "FREE" then do
    address TSO "FREE" payload
    rc = RC
  end
  when mode = "MSG" then do
    say payload
    rc = 0
  end
  otherwise do
    say "LUZ30036 LUTSO invalid mode"
    rc = 8
  end
end

return rc
