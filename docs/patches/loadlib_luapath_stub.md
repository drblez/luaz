# Patch: loadlib LUAPATH stub

## Why

Lua/TSO modules are expected to be loaded from dataset concatenations (DDNAME `LUAPATH`) rather than filesystem paths. Until a dataset loader exists, we must block the default file searcher on z/OS to prevent misleading behavior.

## What changes

- `lua-vm/src/loadlib.c`: define `LUA_PATH_VAR` as `LUAPATH` on z/OS.
- Override `searcher_Lua` under `LUAZ_ZOS` to return a `LUZ43001` error.

## Expected effect

- `require` for Lua source modules fails fast with a clear LUZ‑coded message on z/OS.
- Standard libraries and preloaded Lua/TSO modules still load via `package.preload`.

## How to verify

- With `LUAZ_ZOS` defined, calling `require("anymodule")` should include `LUZ43001` in the error chain.
- Confirm `MSGS-4.md` lists `LUZ43001`.
