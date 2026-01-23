# TSO Host API Contract

## Overview

The `tso` module supports a native backend (IKJEFTSR + DAIR) and a REXX bridge fallback (`LUTSO` via `IRXEXEC`).

`LUAEXEC` runs as a program (`PGM=...`) and `LUACMD` runs as a TSO command processor, both driving the same Lua runtime.
Lua code can check `LUAZ_MODE` to detect whether it runs in `PGM` or `TSO` mode, and `tso.*` APIs should reject calls in `PGM` mode.

`LUACMD` does not use IKJEFTSR program-invocation. Instead, it enters LE with `CEEENTRY`,
then calls the exported C entrypoint (`LUAEXRUN`) directly. This avoids TSO program-mode
parameter conventions and guarantees LE initialization.
Operands from the TSO command line are passed as a single line (pointer + length) to `LUAEXRUN`.
`LUAEXRUN` forces `MODE=TSO` internally and rejects explicit `MODE=PGM` in the input.

### LUACMD CPPL parsing

- `CPPL.CPPLCBUF` points to the command buffer.
- The buffer is `H'len' H'offset' text...` where `text` begins at `buf+offset`.
- `LUACMD` passes `text` and `len - offset` to `LUAEXRUN`.

## Dataset and DDNAME Requirements

- Native backend: output capture uses an internal DDNAME allocated via DAIR; no user DDNAME is required.
- Native backend: the DDNAME value is generated in C (unique per call) and passed into ASM wrappers as an 8-byte EBCDIC DDNAME.
- REXX backend: `SYSEXEC` must include `HLQ.LUA.REXX` with member `LUTSO`.
- REXX backend: `tso.cmd` output capture uses an optional DDNAME (e.g., `TSOOUT`) allocated by the caller.
- REXX backend: `STEPLIB` (or linklist) must include `SYS1.LPALIB` on this system so `IRXEXEC` can be loaded.

### Native output capture lifecycle (DAIR + SYSTSPRT redirect)

The native path captures command output by redirecting `SYSTSPRT` to a private DDNAME using DAIR.

Contract:

1) C generates a unique DDNAME (8 chars) and calls `TSOCMD`:
   - `TSOCMD` allocates the private DDNAME and redirects `SYSTSPRT` to it (DAIR via `TSODALC`).
   - `TSOCMD` executes the TSO command via IKJEFTSR (TSO service facility).
   - `TSOCMD` returns the TSO RC and fills `reason` / `abend` as applicable.
   - `TSOCMD` does **not** free the DD allocations.

2) C reads the captured output from the DDNAME (streaming, with limits) and returns it to Lua as lines.

3) C releases DD allocations by calling `TSODFRE` (DAIR free):
   - restore `SYSTSPRT`,
   - free the private DDNAME.

Notes:

- This keeps “ASM things” (DAIR and TSO/E service facility invocation) in ASM and “C things” (I/O limits, parsing, line splitting, Lua table building) in C.
- IKJEFTSR is called with an OS-style parameter address list (`R1` points to a list of fullword parameter addresses). For unisolated command invocation, `TSOCMD` passes `CPPL` as parm8 and marks end-of-list by setting the high-order bit on the parm8 address. Token (parm9) is omitted unless explicitly needed.
- `DD:`/`//DD:` direct paths bypass LUAMAP and must be read directly from the DDNAME stream (LUAMAP is only for `require` search under `LUAPATH`).

## API Behavior

- `tso.cmd(cmd, opts) -> rc, lines`
  - `cmd`: TSO command string.
  - `opts.outdd`: DDNAME for output capture (REXX backend only).
  - `rc`: TSO return code.
  - `lines`: table of output lines, each prefixed with `LUZ30031`.
- `tso.alloc(spec) -> rc`
  - `spec`: allocation spec (e.g., `DD(LUTMP) DSN('HLQ.DATA') SHR`).
- `tso.free(spec) -> rc`
  - `spec`: free spec (e.g., `DD(LUTMP)`).
- `tso.msg(text, level?) -> rc`
  - `text`: message string (should be `LUZNNNNN ...`).
  - `level`: reserved for future use.
- `tso.exit(rc)`
  - `rc`: process exit code.

## LUAEXEC PARM (current implementation)

Tokens before `--` are parsed as control options. Order does not matter.

- `MODE=TSO` or `MODE=PGM` sets `LUAZ_MODE` (default: `PGM`).
- When invoked from `LUACMD`, `LUAEXRUN` forces `MODE=TSO` regardless of input.
- `DSN=...` is detected but not implemented yet (returns `LUZ30041` and `RC=8`).
- `--` ends control parsing; everything after goes into Lua `arg[]`.
- Any other tokens before `--` are ignored (not passed to Lua).

## LUZ Codes

Refer to `MSGS-3.md` for `LUZ3003x` runtime codes and `LUZ30030`/`LUZ30031` output markers.
