# Patch: loslib os.clock z/OS hook

## Why

CPU time should use a z/OS‑specific source when required. Until that backend exists, `os.clock` should be explicit about missing support under `LUAZ_TIME_ZOS`.

## What changes

- `lua-vm/src/loslib.c`: under `LUAZ_TIME_ZOS`, `os.clock` returns `LUZ-45006`.

## Expected effect

- With `LUAZ_TIME_ZOS` enabled, `os.clock` fails fast until a backend is implemented.

## How to verify

- Build with `-DLUAZ_TIME_ZOS` and call `os.clock()`; expect `LUZ-45006`.
