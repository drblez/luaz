-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO integration test for the tso module.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | fail | function | Raise a LUZ-prefixed error |
-- | expect_rc | function | Assert RC is zero |
-- | main | function | Run tso.cmd/alloc/free checks |
local tso = require("tso")

local function fail(msg)
  error("LUZ00021 " .. msg)
end

local function expect_rc(label, rc)
  if rc ~= 0 then
    fail(label .. " rc=" .. tostring(rc))
  end
end

local function main()
  local rc, lines = tso.cmd("LISTCAT LEVEL(DRBLEZ.LUA)", { outdd = "TSOOUT" })
  expect_rc("tso.cmd", rc)
  if type(lines) ~= "table" or #lines == 0 then
    fail("tso.cmd empty output")
  end
  if type(lines[1]) ~= "string" or not lines[1]:match("^LUZ30031") then
    fail("tso.cmd output missing LUZ30031 prefix")
  end

  rc = tso.alloc("DD(LUTMP) DSN('DRBLEZ.LUA.TEST') SHR")
  expect_rc("tso.alloc", rc)

  rc = tso.free("DD(LUTMP)")
  expect_rc("tso.free", rc)

  tso.msg("LUZ00020 Lua IT OK")
  return 0
end

return main()
