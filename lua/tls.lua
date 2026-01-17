-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO TLS module stubs.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | tls.connect | function | Open TLS connection |
-- | tls.listen | function | Optional TLS server |
local tls = {}

function tls.connect(_)
  error("LUZ14001 tls.connect not implemented")
end

function tls.listen(_)
  error("LUZ14002 tls.listen not implemented")
end

return tls
