# DDNAME/DSN Policy (Draft)

## LUAPATH Scope

- `LUAPATH` contains **only PDS/PDSE** datasets.
- Sequential datasets (PS) are **not** searched via LUAPATH.
- PS is allowed only by explicit `require("DSN=...")` (to be implemented).

## Module Name Mapping

- Module names follow Lua conventions: `a.b.c`.
- Normalize name:
  - Uppercase.
  - Replace `.` with `$`.
  - Replace any non `[A-Z0-9$#@]` with `#`.
- If normalized length **≤ 8**, use it directly as member name.
- If normalized length **> 8**, resolve via `LUAMAP` in each PDS/PDSE, in LUAPATH order:
  - Format: `full.name = MEMBER` (one per line).
  - First match wins.

## Errors

- `LUZ-47001`: invalid module name mapping.
- `LUZ-47002`: LUAMAP entry not found for long name.
- `LUZ-47003`: module source not found in LUAPATH.
- `LUZ-47004`: module load failed.
