# Patch: DDNAME loadfile bypasses LUAMAP

## Why

`DD:...` paths (for example `DD:LUAIN`) represent direct DDNAME input and
must not be resolved via LUAMAP/LUAPATH. LUAMAP is intended only for
module resolution via `require()`.

## What changes

- `lua-vm/src/lauxlib.c`: add `DD:`/`//DD:` detection in `luaL_loadfilex`
  and read the DDNAME stream directly via `fopen` + buffered read.
- `lua-vm/src/lauxlib.c`: fix `mlen` capacity to allow 8-char members.
- `lua-vm/src/loadlib.c`: fix `mlen` capacity to allow 8-char members.

## Expected effect

- `luaL_loadfile("DD:LUAIN")` and other DDNAME paths are loaded directly
  without LUAMAP.
- LUAMAP remains in use only for `require()`/LUAPATH resolution.
- 8-character member names no longer fail due to capacity off-by-one.

## How to verify

- Allocate `LUAIN` DD and run `LUACMD` to load `DD:LUAIN` successfully.
- Run a `require("very.long.name")` where `LUAMAP` maps to a member and
  confirm LUAPATH resolution still works.
