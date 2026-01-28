-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO ds.tmpname unit test via LUACMD.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | fail | function | Emit LUZ00005 and return RC 8 |
-- | main | function | Validate ds.tmpname format |
local ds = require("ds")

local function fail(msg)
  print("LUZ00005 DS TMP UT failed: " .. msg)
  return 8
end

local function main()
  local name, msg = ds.tmpname()
  if not name then
    return fail(msg or "tmpname failed")
  end
  if not name:match("^[A-Z0-9$#@]+%.LUAZ%.TMP%.T[0-9A-F]+$") then
    return fail("tmpname format mismatch")
  end
  if #name > 44 then
    return fail("tmpname length exceeds 44")
  end

  print("LUZ00004 DS TMP UT OK")
  return 0
end

return main()
