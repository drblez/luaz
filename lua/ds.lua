-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO dataset module stubs.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | ds.open_dd | function | Open DDNAME stream |
local ds = {}

function ds.open_dd(_)
  error("LUZ-11001 ds.open_dd not implemented")
end

return ds
