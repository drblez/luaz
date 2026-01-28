-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO ds.member unit test via LUACMD.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | fail | function | Emit LUZ00005 and return RC 8 |
-- | main | function | Validate ds.member formatting |
local ds = require("ds")

local function fail(msg)
  print("LUZ00005 DS MEMBER UT failed: " .. msg)
  return 8
end

local function main()
  local value, msg = ds.member("drblez.lua.test", "memb01")
  if not value then
    return fail(msg or "member format")
  end
  if value ~= "DRBLEZ.LUA.TEST(MEMB01)" then
    return fail("member format mismatch")
  end

  local bad, emsg, ecode = ds.member("DRBLEZ.LUA.TEST", "TOOLONGXX")
  if bad ~= nil or ecode ~= 30029 then
    return fail("invalid member should return LUZ30029")
  end
  if emsg == nil or emsg == "" then
    return fail("invalid member missing message")
  end

  print("LUZ00004 DS MEMBER UT OK")
  return 0
end

return main()
