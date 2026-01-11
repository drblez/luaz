# Patch: loadlib disable C module searchers

## Why

On z/OS, dynamic C module loading is disabled and modules must be linked statically. The C searchers should not attempt to resolve `cpath` entries.

## What changes

- `lua-vm/src/loadlib.c`: under `LUAZ_ZOS`, `searcher_C` and `searcher_Croot` return `LUZ-43002`.

## Expected effect

- Attempts to load C modules via `require` produce a clear LUZ‑coded error message.

## How to verify

- With `LUAZ_ZOS` defined, requiring a C module should include `LUZ-43002` in the error chain.
