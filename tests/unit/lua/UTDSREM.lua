-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO ds.remove unit test via LUACMD.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | fail | function | Emit LUZ00005 and return RC 8 |
-- | main | function | Validate ds.remove behavior |
local ds = require("ds")

local function fail(msg)
  print("LUZ00005 DS REMOVE UT failed: " .. msg)
  return 8
end

local function main()
  local dsn = arg[1]
  if not dsn then
    return fail("missing DSN")
  end

  local ok, msg = ds.remove(dsn)
  if not ok then
    return fail(msg or "remove failed")
  end

  local h, emsg = ds.open_dsn(dsn, "r")
  if h then
    h:close()
    return fail("remove did not delete dataset")
  end
  if not emsg then
    return fail("remove missing error on open")
  end

  print("LUZ00004 DS REMOVE UT OK")
  return 0
end

return main()
