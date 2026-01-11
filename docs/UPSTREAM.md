# Upstream Tracking

This repository uses a hybrid model for the Lua VM:

- `third_party/lua-src/` contains the pristine upstream Lua release.
- `lua-vm/` is the working copy where z/OS‑specific changes are applied.

## Current Baseline

- Lua version: 5.5.0
- Upstream path: `third_party/lua-src/lua-5.5.0/`
- VM working copy: `lua-vm/`

## Update Procedure

1. Place the new upstream release under `third_party/lua-src/` (e.g., `lua-5.5.1`).
2. Run: `scripts/update-lua.sh 5.5.1`
3. Review diffs in `lua-vm/` and update z/OS patches as needed.
4. Update this document and `docs/UPSTREAM_BASELINE.md`.
