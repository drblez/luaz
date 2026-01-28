-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO tso.alloc/free unit test via LUACMD.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | fail | function | Emit LUZ00005 and return RC 8 |
-- | expect_error | function | Assert alloc/free returns LUZ error |
-- | main | function | Validate tso.alloc/tso.free stub behavior |
local tso = require("tso")

local function fail(msg)
  print("LUZ00005 TSO ALLOC/FREE UT failed: " .. msg)
  return 8
end

local function expect_error(label, err, luz)
  if err == nil then
    return fail(label .. " unexpectedly succeeded")
  end
  if err.luz ~= luz then
    return fail(label .. " unexpected luz=" .. tostring(err.luz))
  end
  if err.code == nil then
    return fail(label .. " missing error code")
  end
  return 0
end

local function main()
  -- Change note: expect native alloc/free to fail until DAIR parsing is implemented.
  -- Problem: tso_native_alloc/free are placeholders.
  -- Expected effect: Lua sees LUZ30033/34 errors instead of success.
  -- Impact: test asserts current behavior without using TSO commands.
  local err = tso.alloc("DDNAME(UTDD)")
  if expect_error("tso.alloc", err, 30033) ~= 0 then
    return 8
  end

  local err2 = tso.free("DDNAME(UTDD)")
  if expect_error("tso.free", err2, 30034) ~= 0 then
    return 8
  end

  print("LUZ00004 TSO ALLOC/FREE UT OK")
  return 0
end

return main()
