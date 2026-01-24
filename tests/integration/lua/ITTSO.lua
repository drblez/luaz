-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO integration test for the tso module.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | fail | function | Raise a LUZNNNNN-prefixed error |
-- | expect_rc | function | Assert RC is zero |
-- | main | function | Run tso.cmd checks (direct TSO path) |
--
-- Change note: align prefix format to LUZNNNNN.
-- Problem: prior wording used LUZNNNNN formatting inconsistently in docs.
-- Expected effect: documentation matches emitted message format.
-- Impact: comment-only change; no runtime behavior is altered.
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
  print("LUZ30060 LUAZ_MODE=" .. tostring(LUAZ_MODE))
  -- Change note: restrict ITTSO to direct tso.cmd only (no REXX alloc/free).
  -- Problem: REXX path is out of scope until explicitly approved.
  -- Expected effect: validate direct TSO command execution and output capture.
  -- Impact: ITTSO no longer exercises tso.alloc/free.
  local rc, lines, errcode = tso.cmd("LISTCAT LEVEL(DRBLEZ.LUA)")
  if rc == nil then
    fail("tso.cmd failed: " .. tostring(lines) .. " err=" .. tostring(errcode))
  end
  expect_rc("tso.cmd", rc)
  if type(lines) ~= "table" or #lines == 0 then
    fail("tso.cmd empty output")
  end
  if type(lines[1]) ~= "string" or not lines[1]:match("^LUZ30031") then
    fail("tso.cmd output missing LUZ30031 prefix")
  end

  tso.msg("LUZ00020 Lua IT OK")
  return 0
end

return main()
