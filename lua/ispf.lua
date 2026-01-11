-- Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
--
-- Lua/TSO ISPF module stubs.
--
-- Object Table:
-- | Object | Kind | Purpose |
-- |--------|------|---------|
-- | ispf.qry | function | Query ISPF environment |
-- | ispf.exec | function | Execute ISPF command |
-- | ispf.vget | function | Get ISPF variables |
-- | ispf.vput | function | Put ISPF variables |
local ispf = {}

function ispf.qry()
  error("LUZ-12001 ispf.qry not implemented")
end

function ispf.exec(_)
  error("LUZ-12002 ispf.exec not implemented")
end

function ispf.vget(_,_)
  error("LUZ-12003 ispf.vget not implemented")
end

function ispf.vput(_,_)
  error("LUZ-12004 ispf.vput not implemented")
end

return ispf
