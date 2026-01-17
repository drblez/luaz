-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO TSO module stubs.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | tso.cmd | function | Execute TSO command |
-- | tso.alloc | function | Allocate dataset via TSO |
-- | tso.free | function | Free dataset allocation |
-- | tso.msg | function | Write TSO message |
-- | tso.exit | function | Exit with RC |
local tso = {}

function tso.cmd(_)
  error("LUZ10001 tso.cmd not implemented")
end

function tso.alloc(_)
  error("LUZ10002 tso.alloc not implemented")
end

function tso.free(_)
  error("LUZ10003 tso.free not implemented")
end

function tso.msg(_)
  error("LUZ10004 tso.msg not implemented")
end

function tso.exit(_)
  error("LUZ10005 tso.exit not implemented")
end

return tso
