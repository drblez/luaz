# TSO Host API Contract

## Overview

The `tso` module uses a clean C backend (IKJTSOEV + IKJEFTSR) with JCL-allocated
DDNAMEs. The REXX bridge (`LUTSO` via `IRXEXEC`) is used only when output
capture is explicitly requested.

`LUAEXEC` runs as a program (`PGM=...`) and `LUACMD` runs as a TSO command processor, both driving the same Lua runtime.
Lua code can check `LUAZ_MODE` to detect whether it runs in `PGM` or `TSO` mode, and `tso.*` APIs should reject calls in `PGM` mode.

`LUACMD` does not use IKJEFTSR program-invocation. Instead, it enters LE with `CEEENTRY`,
then calls the exported C entrypoint (`LUAEXRUN`) directly. This avoids TSO program-mode
parameter conventions and guarantees LE initialization.
Operands from the TSO command line are passed as a single line (pointer + length) to `LUAEXRUN`.
`LUAEXRUN` uses only the provided `MODE=` token (default is `PGM`), so `LUACMD`
injects `MODE=TSO` explicitly.
The CPPL pointer is passed by `LUACMD` and cached by `LUAEXEC` for OS-linkage calls.

### LUACMD CPPL parsing

- `CPPL.CPPLCBUF` points to the command buffer.
- The buffer is `H'len' H'offset' text...` where `text` begins at `buf+offset`.
- `LUACMD` passes `text` and `len - offset` to `LUAEXRUN`.
- `LUACMD` passes the CPPL address to `LUAEXRUN` for optional OS-linkage use.

## Dataset and DDNAME Requirements

- Clean C backend: `SYSTSPRT` must be allocated by JCL (dataset or SYSOUT).
- Capture path: `tso.cmd` reads `TSOOUT` directly (`DD:TSOOUT`).
- `tso.alloc` / `tso.free` continue to use DAIR via ASM wrappers.
- Capture path: `SYSEXEC` must include `HLQ.LUA.REXX` with member `LUTSO`.
- Capture path: `STEPLIB` (or linklist) must include `SYS1.LPALIB` so `IRXEXEC` can be loaded.

### Capture lifecycle (TSOOUT via REXX OUTTRAP)

When `capture=true`, `tso.cmd` uses REXX `OUTTRAP` to isolate the command
output and then reads `TSOOUT` directly.

Contract:

1) JCL allocates `SYSTSPRT` (dataset or SYSOUT) for TMP output.
2) REXX `LUTSO` deletes any prior `SYSUID.LUAZ.TSOOUT`, allocates it as `TSOOUT`,
   and traps command output with `OUTTRAP`.
3) REXX writes trapped lines to `DD:TSOOUT` via `EXECIO`.
4) C reads `DD:TSOOUT` (record I/O when possible) and returns captured lines.
5) C issues `FREE DDNAME(TSOOUT) DELETE` to release and delete the dataset.

Notes:

- No DAIR allocation or SYSTSPRT redirection is performed in `LUAEXEC`.
- `DD:`/`//DD:` direct paths bypass LUAMAP and must be read directly from the DDNAME stream (LUAMAP is only for `require` search under `LUAPATH`).

## API Behavior

All `tso.*` APIs return a **single error object** (`err`) on failure.
When `err == nil`, the call is successful. Error details are carried
in a structured table (no string parsing required).

- `tso.cmd(cmd, capture?) -> lines, err`
  - `cmd`: TSO command string.
  - `capture`: optional boolean (default from `tso.cmd.capture.default` in LUACFG).
  - `lines`: table of output lines from `TSOOUT`, each prefixed with `LUZ30031`
    when `capture=true`; `nil` when `capture=false`.
  - `err`: `nil` on success; otherwise a table with fields like:
    `luz`, `code`, `origin`, `stage`, `svc`, `rc`, `rsn`, `abend`,
    `irx_rc`, `rexx_rc`, `verb`.
- `tso.alloc(spec) -> err`
  - `spec`: allocation spec (e.g., `DD(LUTMP) DSN('HLQ.DATA') SHR`).
  - `err`: `nil` on success; otherwise includes `luz=30033` and `spec`.
- `tso.free(spec) -> err`
  - `spec`: free spec (e.g., `DD(LUTMP)`).
  - `err`: `nil` on success; otherwise includes `luz=30034` and `spec`.
- `tso.msg(text, level?) -> err`
  - `text`: message string (should be `LUZNNNNN ...`).
  - `level`: reserved for future use.
- `tso.exit(rc)`
  - `rc`: process exit code.

## LUAEXEC PARM (current implementation)

Tokens before `--` are parsed as control options. Order does not matter.

- `MODE=TSO` or `MODE=PGM` sets `LUAZ_MODE` (default: `PGM`).
- When invoked from `LUACMD`, `MODE=TSO` is injected by LUACMD and parsed by `LUAEXRUN`.
- `DSN=...` is detected but not implemented yet (returns `LUZ30041` and `RC=8`).
- `--` ends control parsing; everything after goes into Lua `arg[]`.
- Any other tokens before `--` are ignored (not passed to Lua).

## LUZ Codes

Refer to `MSGS-3.md` for `LUZ3003x` runtime codes and `LUZ30030`/`LUZ30031` output markers.
