# Patch: loslib os.clock z/OS hook

## Why

CPU time should use a z/OS‑specific source when required. Until that backend exists, `os.clock` should call the z/OS time hook and return a clear error if unimplemented.

## What changes

- `lua-vm/src/loslib.c`: under `LUAZ_TIME_ZOS`, `os.clock` calls `luaz_time_clock`.
- `src/luaz_time.c`: add `luaz_time_clock` stub.

## Expected effect

- With `LUAZ_TIME_ZOS` enabled, `os.clock` returns a z/OS‑specific value once the backend is implemented.

## How to verify

- Build with `-DLUAZ_TIME_ZOS` and call `os.clock()`; expect `LUZ-45006` until backend is implemented.
