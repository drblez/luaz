-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO ds.open_dsn unit test via LUACMD.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | fail | function | Emit LUZ00005 and return RC 8 |
-- | main | function | Validate ds.open_dsn read/write |
local ds = require("ds")

local function rstrip(value)
  return (value:gsub("%s+$", ""))
end

local function fail(msg)
  print("LUZ00005 DSN UT failed: " .. msg)
  return 8
end

local function main()
  local in_dsn = arg[1]
  local out_dsn = arg[2]
  if not in_dsn or not out_dsn then
    return fail("missing DSN args")
  end

  local h, msg = ds.open_dsn(in_dsn, { mode = "r" })
  if not h then
    return fail(msg or "open DSN input")
  end
  local line, err = h:readline()
  if not line then
    h:close()
    return fail(err or "read DSN input")
  end
  if rstrip(line) ~= "HELLO" then
    h:close()
    return fail("read DSN input mismatch")
  end
  local ok, cerr = h:close()
  if not ok then
    return fail(cerr or "close DSN input")
  end

  h, msg = ds.open_dsn(out_dsn, { mode = "w" })
  if not h then
    return fail(msg or "open DSN output write")
  end
  ok, err = h:writeline("WORLD")
  if not ok then
    h:close()
    return fail(err or "write DSN output")
  end
  ok, cerr = h:close()
  if not ok then
    return fail(cerr or "close DSN output")
  end

  h, msg = ds.open_dsn(out_dsn, { mode = "r" })
  if not h then
    return fail(msg or "open DSN output read")
  end
  line, err = h:readline()
  if not line then
    h:close()
    return fail(err or "read DSN output")
  end
  if rstrip(line) ~= "WORLD" then
    h:close()
    return fail("read DSN output mismatch")
  end
  ok, cerr = h:close()
  if not ok then
    return fail(cerr or "close DSN output")
  end

  print("LUZ00004 DSN UT OK")
  return 0
end

return main()
