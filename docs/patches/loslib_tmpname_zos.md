# Patch: loslib os.tmpname restriction

## Why

Temporary filenames based on USS semantics are not reliable for dataset‑based workflows on z/OS.

## What changes

- `lua-vm/src/loslib.c`: disable `os.tmpname` under `LUAZ_ZOS` with `LUZ-44004`.

## Expected effect

- Calls to `os.tmpname()` fail fast with a clear LUZ‑coded error on z/OS.

## How to verify

- With `LUAZ_ZOS` defined, calling `os.tmpname()` returns `LUZ-44004`.
