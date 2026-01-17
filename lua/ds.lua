-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO dataset module stubs.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | ds.open_dd | function | Open DDNAME stream |
-- | ds.remove | function | Remove dataset |
-- | ds.rename | function | Rename dataset |
-- | ds.tmpname | function | Generate temp dataset name |
local ds = {}

function ds.open_dd(_)
  error("LUZ11001 ds.open_dd not implemented")
end

function ds.remove(_)
  error("LUZ11002 ds.remove not implemented")
end

function ds.rename(_, _)
  error("LUZ11003 ds.rename not implemented")
end

function ds.tmpname()
  error("LUZ11004 ds.tmpname not implemented")
end

return ds
