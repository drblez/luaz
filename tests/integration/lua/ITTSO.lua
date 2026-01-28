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
  -- Change note: validate LUACFG-loaded config table.
  -- Problem: runtime config was not visible to Lua scripts.
  -- Expected effect: LUAZ_CONFIG exposes configured policy values.
  -- Impact: ITTSO asserts config-driven behavior.
  if type(LUAZ_CONFIG) ~= "table" then
    fail("LUAZ_CONFIG missing or invalid")
  end
  if LUAZ_CONFIG["allow.tso.cmd"] ~= "whitelist" then
    fail("LUAZ_CONFIG allow.tso.cmd mismatch")
  end
  if LUAZ_CONFIG["tso.cmd.capture.default"] ~= "true" then
    fail("LUAZ_CONFIG capture.default mismatch")
  end
  print("LUZ00024 Lua config OK")
  -- Change note: request explicit output capture via REXX OUTTRAP.
  -- Problem: capture must be opt-in and validated in batch tests.
  -- Expected effect: tso.cmd returns LUZ30031-prefixed output lines.
  -- Impact: ITTSO exercises capture=true path only.
  local rc, lines, errcode = tso.cmd("LISTCAT LEVEL(DRBLEZ.LUA)", true)
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
  -- Change note: echo captured lines for Lua output separation testing.
  -- Problem: test output was only in SYSTSPRT, mixed with debug logs.
  -- Expected effect: Lua output appears in LUAOUT for validation.
  -- Impact: ITTSO prints captured command output lines.
  for i = 1, #lines do
    print(lines[i])
  end
  -- Change note: validate capture default from LUACFG.
  -- Problem: capture default was not configurable.
  -- Expected effect: tso.cmd with no flag uses configured default.
  -- Impact: ITTSO checks capture default behavior.
  local rc2, lines2, errcode2 = tso.cmd("LISTCAT LEVEL(DRBLEZ.LUA)")
  if rc2 == nil then
    fail("tso.cmd default failed: " .. tostring(lines2) .. " err=" .. tostring(errcode2))
  end
  if type(lines2) ~= "table" or #lines2 == 0 then
    fail("tso.cmd default capture missing output")
  end
  -- Change note: validate allowlist policy enforcement.
  -- Problem: tso.cmd allowed any command without policy checks.
  -- Expected effect: non-whitelisted commands are blocked.
  -- Impact: ITTSO asserts allowlist behavior.
  local rc3, err3, code3 = tso.cmd("TIME")
  if rc3 ~= nil then
    fail("tso.cmd policy allowlist did not block TIME")
  end
  if type(err3) ~= "string" or not err3:match("^LUZ30099") then
    fail("tso.cmd policy error missing LUZ30099")
  end
  -- Change note: verify io.write/io.stdout redirection to LUAOUT.
  -- Problem: only print output was validated.
  -- Expected effect: io.write/io.stdout:write output routes to LUAOUT.
  -- Impact: ITTSO emits extra stdout lines for capture checks.
  io.write("LUZ00022 Lua io.write ok\n")
  io.stdout:write("LUZ00023 Lua io.stdout ok\n")

  tso.msg("LUZ00020 Lua IT OK")
  return 0
end

return main()
