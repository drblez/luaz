# LUAPATH/require Contract (z/OS)

## Scope

`require()` resolves modules from datasets allocated to DDNAME `LUAPATH`. `loadfile()` and `dofile()` do the same unless the filename starts with `DD:` or `//DD:`, in which case the DDNAME stream is read directly (no LUAMAP/LUAPATH). Only PDS/PDSE datasets are searched via `LUAPATH`. Sequential datasets (PS) are not searched unless explicitly requested via a DSN form (future work).

## Name Mapping Rules

### Short names (≤ 8)

- Normalize the module name:
  - Uppercase.
  - Replace `.` with `$`.
  - Replace any non `[A-Z0-9$#@]` with `#`.
- If the normalized name length is ≤ 8, it is used directly as the PDS/PDSE member name.

### Long names (> 8)

- Resolve via `LUAMAP` member in `LUAPATH` concatenation (first match wins).
- `LUAMAP` lines are matched **exactly** against the requested module name (case‑sensitive).
  If multiple `LUAMAP` entries exist across the concatenation, the first match
  in `LUAPATH` order is used.

### Collision Policy

- Short names (≤ 8) map directly to a member; collisions are user‑managed.
- Long names (> 8) must be disambiguated in `LUAMAP`.

## LUAMAP Format

- One mapping per line: `full.module.name = MEMBER`.
- Whitespace around names and `=` is ignored.
- Lines starting with `#` or `;` are comments.
- Blank lines are ignored.
- `MEMBER` must be 1–8 chars; allowed chars: `A–Z`, `0–9`, `$`, `#`, `@`.

Example:

```
# Lua/TSO LUAMAP
very.long.name = VLONG01
org.example.util = UTIL001
```

## Error Mapping

- `LUZ47001` — invalid module name mapping
- `LUZ47002` — LUAMAP entry not found for long name
- `LUZ47003` — module source not found in LUAPATH
- `LUZ47004` — module load failed
