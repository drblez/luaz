/* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO REXX bridge for TSO command execution.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | LUTSO  | REXX exec | Execute TSO commands and optional output capture |
 */
parse upper arg mode payload outdd

mode = strip(mode)
outdd = strip(outdd)
rc = 0

select
  when mode = "CMD" then do
    if outdd <> "" then do
      "OUTTRAP LUZOUT."
      address TSO payload
      rc = RC
      "OUTTRAP OFF"
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
