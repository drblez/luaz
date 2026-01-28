-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO tso.msg unit test via LUACMD.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | fail | function | Emit LUZ00005 and return RC 8 |
-- | main | function | Validate tso.msg success path |
local tso = require("tso")

local function fail(msg)
  print("LUZ00005 TSO MSG UT failed: " .. msg)
  return 8
end

local function main()
  local err = tso.msg("LUZ00020 TSO MSG UT")
  if err ~= nil then
    return fail("tso.msg failed luz=" .. tostring(err.luz))
  end

  print("LUZ00004 TSO MSG UT OK")
  return 0
end

return main()
