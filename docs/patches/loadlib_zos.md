# Patch: loadlib z/OS dynamic loading disable

## Why

z/OS deployment for Lua/TSO does not rely on dynamic loading of shared libraries. C modules are expected to be statically linked into `LUAEXEC` or provided by the host runtime.

## What changes

- `lua-vm/src/loadlib.c`: add a z/OS branch (`LUAZ_ZOS`) that disables `dlopen`/symbol lookup and returns `LUZ-41001`/`LUZ-41002` errors.

## Expected effect

- `package.loadlib` and dynamic C module loading fail with explicit LUZ‑coded errors on z/OS.
- C libraries must be linked statically into the runtime.

## How to verify

- In a z/OS build with `LUAZ_ZOS` defined, calling `package.loadlib(...)` should return an error string containing `LUZ-41001`.
- Ensure `MSGS-4.md` lists the new LUZ codes.
