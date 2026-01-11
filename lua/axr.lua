-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO AXR module stubs.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | axr.request | function | AXR request interface (optional) |
local axr = {}

function axr.request(_)
  error("LUZ-13001 axr.request not implemented")
end

return axr
