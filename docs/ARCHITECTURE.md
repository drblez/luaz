# Architecture Overview (Draft)

## Runtime Flow

1. `LUAEXEC` load module starts via TSO/IKJEFT01 or ISPSTART.
2. Core initializes Lua VM and registers host APIs.
3. Script is loaded from DDNAME or dataset member.
4. `require` resolves modules via `LUAPATH` concatenation.
5. Host APIs bridge to TSO/ISPF/AXR/System SSL.

## Integration Points

- TSO: command execution, allocation, message output.
- ISPF: variable pool, LM/TB/FT services (no panels).
- AXR: gateway exec for System REXX integration.
- TLS: System SSL (GSK APIs) and optional AT‑TLS.

## Logging

All user‑visible output must include `LUZNNNNN` and be cataloged in `MSGS-N.md`.
