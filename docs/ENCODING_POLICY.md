# Encoding Policy (Draft)

## Goals

- Define where EBCDIC/ASCII conversion occurs.
- Ensure consistent behavior for scripts, datasets, and console output.

## Proposed Policy

- Script sources: convert to internal UTF‑8 on load.
- Output messages: convert from internal UTF‑8 to EBCDIC when writing to SYSOUT/TSO.
- Dataset I/O: respect dataset encoding settings; default to EBCDIC unless explicitly configured.

## Touchpoints

- `loadfile`/`dofile`/`require` paths from DDNAME.
- `tso.msg` and other user‑visible output (must include `LUZ-*` prefix).
- `ds.open_dd` read/write streams.

## Open Questions

- Confirm IBM conversion APIs to be used (e.g., iconv or LE/OS services).
- Define configuration keys for per‑dataset overrides.
