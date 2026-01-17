# Patch: liolib z/OS I/O restrictions

## Why

Lua/TSO operates on datasets and DDNAME rather than USS files. Standard `io.*` and `popen/tmpfile` are not applicable in the z/OS batch/TSO context.

## What changes

- `lua-vm/src/liolib.c`: add a z/OS branch that disables `io.popen`, `io.open`, and `io.tmpfile`, returning LUZ‑coded errors.

## Expected effect

- Standard file I/O via `io.open` and process pipes via `io.popen` are blocked on z/OS.
- Dataset I/O will be provided through `ds` module instead.

## How to verify

- With `LUAZ_ZOS` defined, calling `io.open(...)` should raise `LUZ42002`.
- Calling `io.popen(...)` should raise `LUZ42001`.
- Calling `io.tmpfile()` should raise `LUZ42003`.
