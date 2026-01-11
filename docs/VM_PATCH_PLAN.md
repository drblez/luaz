# Lua VM Patch Plan (Draft)

## Goals

- Minimize divergence from upstream Lua 5.5.0.
- Route platform differences through small, well‑documented hooks.

## Planned Changes

1. `loadlib.c`
   - Disable shared library loading on z/OS.
   - Add dataset‑based module search using `LUAPATH` DDNAME concatenation.
   - Implemented: z/OS dynamic loading disabled with LUZ codes (see `docs/patches/loadlib_zos.md`).

2. `liolib.c`
   - Replace file I/O with DDNAME dataset access hooks.
   - Enforce encoding policy on read/write boundaries.

3. `loslib.c`
   - Provide z/OS‑safe implementations for time/env/exit.

4. `linit.c`
   - Register Lua modules: `tso`, `ds`, `ispf`, `axr`, `tls`.

## Patch Delivery

- Store each patch under `patches/` with a short rationale.
- Track applied patches in `docs/UPSTREAM.md`.
