# Patch: LUAPATH DDNAME I/O helpers

## Why

LUAPATH members and LUAMAP need to be read from PDS/PDSE datasets allocated to DDNAME `LUAPATH`.

## What changes

- `src/luaz_io_dd.c`: adds DDNAME-based reader using `//DD:LUAPATH(member)`.
- `luaz_io_dd_register()` wires these readers into `luaz_platform_set_ops`.

## Expected effect

- `luaz_path_lookup`/`luaz_path_load` can read `LUAMAP` and module members via LUAPATH DDNAME.

## How to verify

- Allocate `LUAPATH` DD to a PDS containing `LUAMAP` and a module member.
- Call `luaz_io_dd_register()` and verify `require()` resolves modules.
