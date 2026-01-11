# Patch: linit optional Lua/TSO libraries

## Why

Lua/TSO provides host APIs (`tso`, `ds`, `ispf`, `axr`, `tls`) that may be built as C modules. We need a controlled way to preload them without breaking upstream library order assumptions.

## What changes

- `lua-vm/src/linit.c`: introduce `luazlibs` list gated by build flags (`LUAZ_WITH_*`).
- Register these modules into `package.preload` after standard library handling.

## Expected effect

- When `LUAZ_WITH_*` flags are defined, `require("tso")`, `require("ds")`, etc. resolve via preload.
- When flags are not defined, standard Lua behavior is unchanged and Lua modules can be loaded via `require` searchers.

## How to verify

- Build with `-DLUAZ_WITH_TSO` and confirm `package.preload.tso` is set.
- Without flags, ensure `package.preload` contains only standard libs.
