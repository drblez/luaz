# Patch: loslib z/OS restrictions

## Why

Lua/TSO uses TSO and dataset APIs for system actions. Standard `os.execute`, `os.remove`, and `os.rename` are not appropriate in the z/OS batch/TSO context.

## What changes

- `lua-vm/src/loslib.c`: disable `os.execute`, `os.remove`, and `os.rename` under `LUAZ_ZOS` with LUZ‑coded errors.

## Expected effect

- Calls to `os.execute`, `os.remove`, `os.rename` fail fast with explicit LUZ codes on z/OS.
- Users are guided toward `tso` and `ds` APIs for system and dataset operations.

## How to verify

- With `LUAZ_ZOS` defined, `os.execute()` -> `LUZ44001`.
- `os.remove()` -> `LUZ44002`.
- `os.rename()` -> `LUZ44003`.
