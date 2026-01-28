-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO ds.rename unit test via LUACMD.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | fail | function | Emit LUZ00005 and return RC 8 |
-- | main | function | Validate ds.rename behavior |
local ds = require("ds")

local function fail(msg)
  print("LUZ00005 DS RENAME UT failed: " .. msg)
  return 8
end

local function main()
  local old_dsn = arg[1]
  local new_dsn = arg[2]
  if not old_dsn or not new_dsn then
    return fail("missing DSN args")
  end

  local ok, msg = ds.rename(old_dsn, new_dsn)
  if not ok then
    return fail(msg or "rename failed")
  end

  local h, emsg = ds.open_dsn(new_dsn, "r")
  if not h then
    return fail(emsg or "open renamed dataset")
  end
  h:close()

  local h_old = ds.open_dsn(old_dsn, "r")
  if h_old then
    h_old:close()
    return fail("old dataset still exists")
  end

  print("LUZ00004 DS RENAME UT OK")
  return 0
end

return main()
