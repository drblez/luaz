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

## Observations (FTP Sync)

- FTP sync to PDS applies ASCII->EBCDIC conversion for both ASM and C sources.
- Verified via ASM listing: `STRABC DC C'ABC'` assembled to bytes `C1C2C3`.
- Verified via C runtime output in `UT_EBCCHK` (`LUZ40080` prints `C1 C2 C3`).
- Implication: string/byte comparisons in `LUAEXEC` should assume EBCDIC after FTP sync unless a non-converting transfer is used.

## Open Questions

- Confirm IBM conversion APIs to be used (e.g., iconv or LE/OS services).
- Define configuration keys for per‑dataset overrides.
