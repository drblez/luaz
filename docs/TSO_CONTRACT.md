# TSO Host API Contract

## Overview

The `tso` module executes TSO commands from batch using the REXX bridge `LUTSO` (member in `HLQ.LUA.REXX`) invoked via `IRXEXEC`.

## Dataset and DDNAME Requirements

- `SYSEXEC` must include `HLQ.LUA.REXX` with member `LUTSO`.
- `tso.cmd` output capture uses an optional DDNAME (e.g., `TSOOUT`) allocated by the caller.
- `STEPLIB` (or linklist) must include `SYS1.LPALIB` on this system so `IRXEXEC` can be loaded.

## API Behavior

- `tso.cmd(cmd, opts) -> rc, lines`
  - `cmd`: TSO command string.
  - `opts.outdd`: DDNAME for output capture (optional).
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

## LUZ Codes

Refer to `MSGS-3.md` for `LUZ3003x` runtime codes and `LUZ30030`/`LUZ30031` output markers.
