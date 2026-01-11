# z/OS C/LE Build Notes (Draft)

This document records planned build settings for the Lua/TSO C core on z/OS.

## Compiler/Linker Targets

- Compiler: XL C/C++ (C/LE)
- Addressing: 31‑bit or 64‑bit (explicitly documented per build)
- Linkage: LE‑enabled, reentrant

## Suggested Flags (to be validated)

- C flags: `-q64 -qlanglvl=extc99 -qreentrant -qhaltonmsg=CCN0001`
- Link flags: `-q64 -Wl,REUS,RENT`

## Outputs

- `LUAEXEC` load module
- Static library for Lua core (if needed)

## Notes

- Any EBCDIC/ASCII conversion policy is defined in `docs/ENCODING_POLICY.md`.
- Update this file as soon as a real z/OS build is available.
