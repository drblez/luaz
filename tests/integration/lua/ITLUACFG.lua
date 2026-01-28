-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- LUACFG integration test for LUAZ_CONFIG exposure and DD overrides.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | fail | function | Raise a LUZNNNNN-prefixed error |
-- | expect | function | Assert LUAZ_CONFIG key matches expected value |
-- | main | function | Validate LUAZ_CONFIG table content |
-- Raise a LUZNNNNN-prefixed error for test failures.
local function fail(msg)
  error("LUZ00043 " .. msg)
end

-- Assert that LUAZ_CONFIG has a specific key/value pair.
local function expect(key, expected)
  local value = nil
  if type(LUAZ_CONFIG) == "table" then
    value = LUAZ_CONFIG[key]
  end
  if value ~= expected then
    fail("LUAZ_CONFIG " .. tostring(key) .. " mismatch value=" .. tostring(value) ..
      " expected=" .. tostring(expected))
  end
end

-- Run LUACFG integration checks.
local function main()
  -- Change note: validate LUACFG-driven config values in Lua runtime.
  -- Problem: config-driven DD overrides lacked a dedicated integration test.
  -- Expected effect: LUAZ_CONFIG exposes LUACFG values and overrides are honored.
  -- Impact: IT_LUACFG catches regressions in LUACFG parsing/exposure.
  if type(LUAZ_CONFIG) ~= "table" then
    fail("LUAZ_CONFIG missing or invalid")
  end

  expect("allow.tso.cmd", "whitelist")
  expect("tso.cmd.capture.default", "false")
  expect("limits.output.lines", "10")
  expect("luain.dd", "CFGIN")
  expect("luaout.dd", "CFGOUT")
  expect("luapath.dd", "LUAPATH")

  if LUAZ_CONFIG["unknown.key"] ~= nil then
    fail("LUAZ_CONFIG unexpected key present")
  end

  print("LUZ00042 LUACFG IT OK")
  return 0
end

return main()
