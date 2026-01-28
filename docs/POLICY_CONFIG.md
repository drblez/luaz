# Policy/Config Dataset (Draft)

This document describes the planned configuration policy dataset.

## Format

- Dataset member: `LUACONF`
- Syntax: key = value (ASCII or EBCDIC per `ENCODING_POLICY.md`)

## Core Keys

- `allow.tso.cmd` — whitelist/blacklist mode (`whitelist` or `blacklist`)
- `tso.cmd.whitelist` — comma‑separated command list
- `tso.cmd.blacklist` — comma‑separated command list
- `trace.level` — `off`, `error`, `info`, `debug`
- `limits.output.lines` — max output lines per command

## TLS Keys

- `tls.keyring` — SAF key ring name
- `tls.pkcs11.token` — PKCS#11 token name
- `tls.profile` — profile selector

## Notes

- Validate all keys at startup and emit `LUZNNNNN` messages on errors.
