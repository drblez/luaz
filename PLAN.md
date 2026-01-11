# Migration Plan — Lua VM to z/OS (C/LE) per RFC

This plan targets the RFC in `docs/RFC_MAIN.md` / `docs/RFC_MAIN_EN.md` and prepares Lua 5.5.0 for z/OS C/LE integration and host APIs.

## 1) Baseline & Inventory

- [x] Record upstream baseline: `third_party/lua/lua-5.5.0/` (source list in `src/`).
- [x] Identify Lua subsystems and touchpoints: VM/core (`lvm.c`, `ldo.c`, `lgc.c`), I/O (`liolib.c`, `loslib.c`), dynamic loading (`loadlib.c`), init (`linit.c`).
- [x] Create patch staging area: `patches/` for all Lua modifications (one patch per concern).
- [x] Establish hybrid upstream tracking (`third_party/lua-src/` + `lua-vm/`).

## 2) Build System for z/OS C/LE

- [ ] Define compiler/linker settings for XL C/C++ and LE (31/64‑bit target), include paths, and EBCDIC handling.
- [ ] Replace/augment upstream `src/Makefile` with a z/OS‑specific build script (e.g., `make zos`, or a separate `build/` script).
- [ ] Produce `LUAEXEC` load module and any required static libs.

## 3) Platform Abstraction Layer

- [x] Introduce a thin z/OS platform layer for:
  - file/dataset access (DDNAME, PS/PDS/PDSE),
  - environment/config (policy dataset),
  - console/logging (LUZ‑codes),
  - time/process primitives where needed.
- [~] Keep Lua core changes minimal; route platform differences through a small set of hooks.

## 4) Dataset‑first I/O and `require`

- [ ] Implement dataset‑backed file access for `loadfile`, `dofile`, and `require` search via `LUAPATH` DDNAME concatenation.
- [ ] Define module search order and error messaging per RFC.

## 5) Host APIs (C Core + Lua libs)

- [ ] Implement `tso`, `ds`, `ispf`, `axr` in the C core and expose Lua modules:
  - `tso.cmd`, `tso.alloc`, `tso.free`, `tso.msg`, `tso.exit`.
  - `ds.open_dd` stream interface.
  - `ispf.qry`, `ispf.exec`, `ispf.vget/vput`, minimal LM/TB/FT wrappers.
  - AXR mode A gateway (`LUAXR` REXX exec) and optional AXREXX helpers.

## 6) TLS via System SSL

- [ ] Implement `tls.*` in C using GSK APIs.
- [ ] Support SAF key ring / PKCS#11 token selection via `GSK_KEYRING_FILE`.
- [ ] Optional CMS API integration if needed.

## 7) Encoding & EBCDIC

- [ ] Define conversion policy for script sources and output messages.
- [ ] Ensure all user/log output uses `LUZ-NNNNN` prefixes and is registered in `MSGS-N.md`.

## 8) ISPF in Batch & JCL Support

- [ ] Provide JCL examples for TMP/ISPSTART usage and dataset allocations.
- [ ] Validate that ISPF services work without panels.

## 9) Testing Harness

- [ ] Create a batch‑friendly test runner (RC≠0 on failure).
- [ ] Add unit/integration/regression suites for datasets, TSO, ISPF, AXR, TLS.

## 10) Packaging & Delivery

- [ ] Define dataset layout: `HLQ.LUA.LOAD`, `HLQ.LUA.LIB`, `HLQ.LUA.APP`, `HLQ.LUA.TEST`, `HLQ.LUA.CONF`.
- [ ] Provide install/run documentation and example JCL.

## 11) MVP Checkpoint (RFC §13)

- [ ] Batch launch via IKJEFT01/SYSTSIN.
- [ ] `tso.cmd`, `ds.open_dd`, `require` via `LUAPATH`.
- [ ] ISPF services without panels.
- [ ] AXR mode A gateway `LUAXR`.
- [ ] `tls.connect/read/write/close` on System SSL.

## Pre‑mainframe Work (no MF access)

- [x] Design the platform abstraction layer and define C headers for TSO/ISPF/AXR/TLS hooks.
- [x] Draft stub implementations and Lua module skeletons with clear contracts and `LUZ-*` messages.
- [x] Prepare build scripts and compiler/linker flags for z/OS C/LE (documented, even if not runnable).
- [x] Create `MSGS-N.md` catalogs for all planned `LUZ-*` messages.
- [x] Write JCL templates for IKJEFT01/ISPSTART and dataset allocations.
- [x] Define EBCDIC/ASCII conversion policy and annotate all I/O touchpoints.
- [x] Produce a test plan and fixture layout for batch‑mode execution.
- [x] Create C core skeletons for host APIs and reserve LUZ ranges.
- [x] Draft policy/config format and architecture overview docs.
- [x] Document Lua VM touchpoints and patch plan.
- [x] Define LUZ error constants and return codes in C stubs.
- [x] Add a local build scaffold for C stubs.
- [x] Add reserved message catalog for dataset I/O errors.
- [x] Implement z/OS dynamic loading disable in `lua-vm/src/loadlib.c`.
- [x] Restrict standard I/O in `lua-vm/src/liolib.c` for z/OS.
- [x] Add optional Lua/TSO module preload in `lua-vm/src/linit.c`.

## Deliverables

- z/OS build scripts and Lua core patches in `patches/`.
- C core host API with documented `LUZ-*` messages.
- JCL samples and test harness.
- Updated RFC sections as implementation details evolve.
