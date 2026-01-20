-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO MVS module stubs.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | mvs.console | function | Execute MVS console command |
--
-- User Actions:
-- - Run under TMP with proper authorization when implemented.
-- - Ensure console command authority is granted by security.
local mvs = {}

function mvs.console(_)
  error("LUZ15001 mvs.console not implemented")
end

return mvs
