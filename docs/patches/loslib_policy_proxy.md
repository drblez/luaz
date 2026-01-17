# Patch: loslib policy‑proxy for getenv/setlocale

## Why

Environment and locale should be controlled via policy datasets on z/OS rather than process environment variables.

## What changes

- `lua-vm/src/loslib.c`: under `LUAZ_POLICY`, `os.getenv` reads from policy; `os.setlocale` returns configured locale or errors.
- Add policy stubs in core (`src/luaz_policy.c`) and headers (`include/luaz_policy.h`, `lua-vm/src/luaz_policy_stub.h`).

## Expected effect

- `os.getenv` returns values from `LUACONF` (policy) when `LUAZ_POLICY` is enabled.
- `os.setlocale` is controlled and does not change process‑wide locale.

## How to verify

- Build with `-DLUAZ_POLICY` and call `os.getenv("key")`; expect `LUZ46001` until policy backend is implemented.
- Call `os.setlocale()` and verify it returns policy locale or `LUZ46002`.
