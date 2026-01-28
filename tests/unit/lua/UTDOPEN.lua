-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO ds.open_dd unit test via LUACMD.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | fail | function | Emit LUZ00005 and return RC 8 |
-- | main | function | Validate ds.open_dd read/write |
local ds = require("ds")

local function rstrip(value)
  return (value:gsub("%s+$", ""))
end

local function fail(msg)
  print("LUZ00005 DS UT failed: " .. msg)
  return 8
end

local function main()
  local h, msg = ds.open_dd("DSIN", { mode = "r" })
  if not h then
    return fail(msg or "open DSIN")
  end
  local line, err = h:readline()
  if not line then
    h:close()
    return fail(err or "read DSIN")
  end
  if rstrip(line) ~= "HELLO" then
    h:close()
    return fail("read DSIN mismatch")
  end
  local ok, cerr = h:close()
  if not ok then
    return fail(cerr or "close DSIN")
  end

  h, msg = ds.open_dd("DSOUT", { mode = "w" })
  if not h then
    return fail(msg or "open DSOUT write")
  end
  ok, err = h:writeline("WORLD")
  if not ok then
    h:close()
    return fail(err or "write DSOUT")
  end
  ok, cerr = h:close()
  if not ok then
    return fail(cerr or "close DSOUT")
  end

  h, msg = ds.open_dd("DSOUT", { mode = "r" })
  if not h then
    return fail(msg or "open DSOUT read")
  end
  line, err = h:readline()
  if not line then
    h:close()
    return fail(err or "read DSOUT")
  end
  if rstrip(line) ~= "WORLD" then
    h:close()
    return fail("read DSOUT mismatch")
  end
  ok, cerr = h:close()
  if not ok then
    return fail(cerr or "close DSOUT")
  end

  print("LUZ00004 DS UT OK")
  return 0
end

return main()
