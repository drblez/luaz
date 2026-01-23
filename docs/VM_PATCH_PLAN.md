# Lua VM Patch Plan (Draft)

## Goals

- Minimize divergence from upstream Lua 5.5.0.
- Route platform differences through small, well‑documented hooks.

## Planned Changes

1. `loadlib.c`
   - Disable shared library loading on z/OS.
   - Add dataset‑based module search using `LUAPATH` DDNAME concatenation.
   - Implemented: z/OS dynamic loading disabled with LUZ codes (see `docs/patches/loadlib_zos.md`).
   - Implemented: LUAPATH stub searcher for z/OS (see `docs/patches/loadlib_luapath_stub.md`).
   - Implemented: disable C module searchers for z/OS (see `docs/patches/loadlib_cdisable_zos.md`).
   - Implemented: LUAPATH mapping with LUAMAP (see `docs/patches/loadlib_luapath_map.md`).
   - Implemented: LUAPATH DDNAME readers (see `docs/patches/luapath_dd_io.md`).

2. `liolib.c`
   - Replace file I/O with DDNAME dataset access hooks.
   - Enforce encoding policy on read/write boundaries.
   - Implemented: z/OS disables io.open/popen/tmpfile with LUZ codes (see `docs/patches/liolib_zos.md`).

3. `loslib.c`
   - Provide z/OS‑safe implementations for time/env/exit.
   - Implemented: disable os.execute/remove/rename under z/OS (see `docs/patches/loslib_zos.md`).
   - Implemented: disable os.tmpname under z/OS (see `docs/patches/loslib_tmpname_zos.md`).
   - Implemented: disable os.exit under z/OS (see `docs/patches/loslib_exit_zos.md`).
   - Implemented: z/OS time backend hooks (see `docs/patches/loslib_time_zos.md`).
   - Implemented: proxy os.* calls to `tso`/`ds` modules (see `docs/patches/loslib_proxy_zos.md`).
   - Implemented: policy‑proxy for getenv/setlocale (see `docs/patches/loslib_policy_proxy.md`).
   - Implemented: `os.clock` z/OS hook (see `docs/patches/loslib_clock_zos.md`).

4. `linit.c`
   - Register Lua modules: `tso`, `ds`, `ispf`, `axr`, `tls`.
   - Implemented: optional preload gated by `LUAZ_WITH_*` flags (see `docs/patches/linit_luazlibs.md`).

5. `lauxlib.c`
   - Ensure `DD:`/`//DD:` loadfile reads bypass LUAMAP/LUAPATH.
   - Implemented: DDNAME loadfile bypass and mlen fix (see `docs/patches/lauxlib_dd_loadfile.md`).

## Patch Delivery

- Store each patch under `patches/` with a short rationale.
- Track applied patches in `docs/UPSTREAM.md`.
