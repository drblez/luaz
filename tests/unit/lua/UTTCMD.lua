-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO tso.cmd unit test via LUACMD.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | fail | function | Emit LUZ00005 and return RC 8 |
-- | main | function | Validate tso.cmd no-capture path |
local tso = require("tso")

local function fail(msg)
  print("LUZ00005 TSO CMD UT failed: " .. msg)
  return 8
end

local function main()
  local lines, err = tso.cmd("TIME", false)
  if err ~= nil then
    return fail("tso.cmd failed luz=" .. tostring(err.luz))
  end
  if lines ~= nil then
    return fail("tso.cmd returned output on no-capture path")
  end

  print("LUZ00004 TSO CMD UT OK")
  return 0
end

return main()
