-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO ds.info unit test via LUACMD.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | fail | function | Emit LUZ00005 and return RC 8 |
-- | main | function | Validate ds.info metadata |
local ds = require("ds")

local function fail(msg)
  print("LUZ00005 DS INFO UT failed: " .. msg)
  return 8
end

local function main()
  local dsn = arg[1]
  if not dsn then
    return fail("missing DSN")
  end

  local info, msg = ds.info(dsn)
  if not info then
    return fail(msg or "info failed")
  end

  if info.recfm ~= "FB" then
    return fail("recfm mismatch: " .. tostring(info.recfm))
  end
  if info.lrecl ~= 80 then
    return fail("lrecl mismatch: " .. tostring(info.lrecl))
  end
  if info.dsorg ~= "PS" and (not info.dsorg_flags or not info.dsorg_flags.PS) then
    return fail("dsorg mismatch")
  end

  print("LUZ00004 DS INFO UT OK")
  return 0
end

return main()
