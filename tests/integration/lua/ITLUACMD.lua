-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- LUACMD -> LUAEXEC integration test (MODE=TSO propagation).
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | main | function | Verify LUAZ_MODE is TSO when invoked via LUACMD |
--
-- User Actions:
-- - Run via LUACMD under IKJEFT01 (TMP).
-- - Ensure LUAIN points to this member.
local function main()
  if LUAZ_MODE ~= "TSO" then
    print(string.format("LUZ30071 ITLUACMD expected LUAZ_MODE=TSO got=%s", tostring(LUAZ_MODE)))
    return 8
  end
  print("LUZ30070 ITLUACMD ok LUAZ_MODE=TSO")
  return 0
end

return main()
