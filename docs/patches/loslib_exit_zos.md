# Patch: loslib os.exit restriction

## Why

Process termination should be controlled by the host runtime on z/OS (TSO/AXR/JCL), not by Lua scripts directly.

## What changes

- `lua-vm/src/loslib.c`: disable `os.exit` under `LUAZ_ZOS` with `LUZ44005`.

## Expected effect

- Calls to `os.exit()` fail fast with a clear LUZ‑coded error on z/OS.
- Host APIs (e.g., `tso.exit`) control return codes and termination.

## How to verify

- With `LUAZ_ZOS` defined, calling `os.exit()` returns `LUZ44005`.
