-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- LUACMD -> LUAEXEC integration test (automatic MODE=TSO pass-through).
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | main | function | Verify LUAZ_MODE and operand pass-through via LUACMD |
--
-- User Actions:
-- - Run via LUACMD under IKJEFT01 (TMP).
-- - Ensure LUAIN points to this member.
local function fail(msg)
  print(string.format("LUZ30071 ITLUACMD validation failed: %s", msg))
  return 8
end

local function main()
  if LUAZ_MODE ~= "TSO" then
    return fail(string.format("LUAZ_MODE expected TSO got=%s", tostring(LUAZ_MODE)))
  end
  -- Change note: add script and count checks for LUACMD argument pass-through.
  -- Problem: missing/extra args can go unnoticed without strict validation.
  -- Expected effect: assert LUAIN script name and exact arg list length.
  -- Impact: ITLUACMD fails fast if LUACMD argument handling regresses.
  if arg[0] ~= "DD:LUAIN" then
    return fail(string.format("arg[0] expected DD:LUAIN got=%s", tostring(arg[0])))
  end
  if arg[1] ~= "ARG1" then
    return fail(string.format("arg[1] expected ARG1 got=%s", tostring(arg[1])))
  end
  if arg[2] ~= "ARG TWO" then
    return fail(string.format("arg[2] expected ARG TWO got=%s", tostring(arg[2])))
  end
  if arg[3] ~= "ARG3=Z" then
    return fail(string.format("arg[3] expected ARG3=Z got=%s", tostring(arg[3])))
  end
  if arg[4] ~= "ARG4" then
    return fail(string.format("arg[4] expected ARG4 got=%s", tostring(arg[4])))
  end
  if arg[5] ~= nil then
    return fail(string.format("arg[5] expected nil got=%s", tostring(arg[5])))
  end
  print("LUZ30070 ITLUACMD ok LUAZ_MODE=TSO args ok")
  return 0
end

return main()
