# Patch: loadlib LUAPATH mapping with LUAMAP

## Why

z/OS PDS/PDSE member names are limited to 8 characters. Lua module names are not. We need a deterministic mapping and a lookup table for long names.

## What changes

- `lua-vm/src/loadlib.c`: call LUAPATH resolver/loader hooks:
  - `luaz_path_resolve` maps module name to member,
  - `luaz_path_load` loads module source.
- `src/luaz_path.c`: implement mapping logic for short names (≤8) and LUAMAP lookup for long names.
- `src/luaz_platform.c`: bind LUAPATH hooks from platform ops.
  - uses direct member names for normalized names ≤ 8,
  - for longer names, consults `LUAMAP` entries in each PDS/PDSE (LUAPATH order).
- Add LUAPATH hooks: `luaz_path_lookup` and `luaz_path_load`.

## Expected effect

- Short module names resolve directly to PDS members.
- Long module names resolve through LUAMAP; collisions are avoided.

## How to verify

- With LUAMAP entry `very.long.name = VLONG001`, `require("very.long.name")` resolves to member `VLONG001`.
- Missing LUAMAP entry yields `LUZ-47002`.
