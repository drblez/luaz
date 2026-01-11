# Lua VM Touchpoints (Draft)

This document lists upstream Lua files that likely require changes for z/OS.

## I/O and Module Loading

- `lua-vm/src/loadlib.c` — override dynamic library loading and module search paths.
- `lua-vm/src/liolib.c` — dataset/ DDNAME I/O and binary/text mode handling.
- `lua-vm/src/loslib.c` — OS functions (env, time, locale) to map to z/OS services.

## Initialization

- `lua-vm/src/linit.c` — register host APIs (`tso`, `ds`, `ispf`, `axr`, `tls`).
- `lua-vm/src/lua.c` — entry point wiring to LUAEXEC on z/OS.

## Encoding

- `lua-vm/src/lstring.c` / `lua-vm/src/lutf8lib.c` — ensure correct UTF‑8/EBCDIC boundary handling.
