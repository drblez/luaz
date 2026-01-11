# Patch: loslib z/OS time backend (hybrid)

## Why

Date/time should support z/OS‑specific backends while keeping default LE behavior. This enables controlled behavior without breaking upstream semantics.

## What changes

- `lua-vm/src/loslib.c`: when `LUAZ_TIME_ZOS` is defined, delegate `os.date`/`os.time` to `luaz_time_date`/`luaz_time_time`.
- `src/luaz_time.c`: provide stubs for date/time formatting and time computation.

## Expected effect

- With `LUAZ_TIME_ZOS` defined, `os.date` and `os.time` depend on z/OS hooks and emit LUZ errors if unimplemented.
- Without the flag, standard Lua behavior remains unchanged.

## How to verify

- Build with `-DLUAZ_TIME_ZOS` and call `os.time()`; expect `LUZ-30023` until backend is implemented.
- Build without the flag and confirm standard behavior.
