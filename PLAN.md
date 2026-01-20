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
- [x] Implement PDSE hash-based incremental compile (HASHCMP tool + JCL PROC).
- [x] Validate incremental build on MF (compile only changed modules, update hashes, link OK).
- [x] Provide FTP scripts for submit/sync and per‑step spool extraction.

## 3) Platform Abstraction Layer

- [x] Introduce a thin z/OS platform layer for:
  - file/dataset access (DDNAME, PS/PDS/PDSE),
  - environment/config (policy dataset),
  - console/logging (LUZ‑codes),
  - time/process primitives where needed.
- [~] Keep Lua core changes minimal; route platform differences through a small set of hooks.

## 4) Dataset‑first I/O and `require`

- [x] Implement dataset‑backed file access for `loadfile`, `dofile`, and `require` search via `LUAPATH` DDNAME concatenation.
- [x] Define module search order and error messaging per RFC.
- [x] Implement `luapath_read_luamap` and `luapath_read_member` in host runtime.
- [~] Finalize LUAMAP format and collision policy (document + tests).
- [x] Implement `ds.open_dd` host runtime (read/write) + unit tests.

## 5) Host APIs — TSO Native (C only, no REXX)

This section replaces the REXX bridge and focuses only on native TSO services.

- [~] **Docs & contracts (IBM sources)**
  - [x] Record core IBM references for IKJEFTSR, DAIR/DAIRFAIL, IKJTBLS, GETMSG, IKJTSOEV.
  - [~] Extract parameter‑list layouts and required control blocks into `docs/TSO_NATIVE.md`.
  - [~] Extract DAIR parameter list from `SYS1.MACLIB(IKJDAIR)` and codify structs.
    - [x] Add JCL to print `IKJDAIR` and `IKJEFFDF` from `SYS1.MACLIB`.
    - [x] Run JCL on MF and capture macro content into `docs/`.
      - [x] Extracted `IKJDAPL`, `IKJDAP00/04/08/10/14/18`, `IKJEFFDF` to `docs/`.
  - [~] Define C structs/prototypes in `include/` with explicit field sizes and AMODE notes.
- [~] **Core environment bootstrap**
  - [~] Implement `tso_native_env_init()` to validate TMP context (IKJEFT01).
  - [ ] Emit a clear LUZ error when no TMP context is available.
  - [~] Add UT JCL to validate TMP detection without command execution (UTTSNENV).
- [~] **TSO command execution (IKJEFTSR)**
  - [~] Implement `tso_native_cmd()` using IKJEFTSR.
    - [~] Add unit test program + JCL (TSNUT/UTTSN).
  - [ ] Output capture strategy (TMP required):
    - [ ] Route command output to DD and read back into Lua (preferred).
    - [ ] Optional: GETMSG buffer fallback for message capture.
  - [ ] Map IKJEFTSR RC/RSN to LUZ codes and Lua errors.
  - [ ] UT JCL: `TIME`, `LISTCAT`, verify non‑empty output.
- [ ] **Dynamic allocation (DAIR/DAIRFAIL)**
  - [ ] Implement `tso_native_alloc()` and `tso_native_free()` via DAIR.
  - [ ] Normalize allocation options parsing (DD, DSN, DISP, RECFM, LRECL, BLKSIZE, SPACE).
  - [ ] Convert DAIR/DAIRFAIL RC/RSN to LUZ codes with user actions.
  - [ ] UT JCL: ALLOC/FREE temp datasets, verify DD existence.
- [ ] **Message handling**
  - [ ] Implement `tso_native_msg()` to emit to SYSTSPRT/SYSOUT.
  - [ ] Ensure `LUZNNNNN` prefix enforcement and catalog entries.
- [ ] **Lua module wiring**
  - [ ] Wire native backend into `tso.*` behind a build flag/policy switch.
  - [ ] Keep REXX path present but disabled by default.
- [ ] **Tests & diagnostics**
  - [ ] Add UT JCL for `tso.cmd`, `tso.alloc/free`, `tso.msg`.
  - [ ] Add Lua integration test for `tso.cmd` with output capture and RC checks.
  - [ ] Ensure new LUZ codes are recorded in `MSGS-*.md` with user actions.
- [ ] **Cleanup**
  - [ ] Remove temporary debug prints; keep only stable LUZ outputs.
  - [ ] Update docs with final behavior and examples.
  - [ ] **ds module (z/OS-specific):**
    - [ ] `ds.open_dd(ddname, mode)` — DDNAME stream (done).
    - [ ] `ds.open_dsn(dsn, mode)` — direct DSN open (PS/PDS/PDSE).
    - [ ] `ds.member(dsn, member)` — PDS/PDSE member helpers.
    - [ ] `ds.info(dsn)` — dataset metadata (DSORG/RECFM/LRECL/BLKSIZE).
  - [ ] **ispf module (z/OS-specific):**
    - [ ] `ispf.qry()` — ISPF active check.
    - [ ] `ispf.exec(cmdline)` — raw ISPEXEC.
    - [ ] `ispf.vget/vput/vdefine/vreset` — variable pool.
    - [ ] `ispf.lm*` — LM services (LMINIT/LMOPEN/LMGET/LMFREE).
    - [ ] `ispf.tb*` — TB services (TBCREATE/TBOPEN/TBADD/TBGET/TBPUT/TBCLOSE).
    - [ ] `ispf.ft*` — File tailoring (FTOPEN/FTINCL/FTCLOSE).
    - [ ] `ispf.libdef` — LIBDEF wrappers.
  - [ ] **axr module (z/OS-specific):**
    - [ ] Mode A gateway: REXX `LUAXR` exec -> `LUAEXEC`.
    - [ ] Optional AXREXX: `axr.exec/cancel/getrexxlib`.
  - [ ] **tls module (z/OS-specific):**
    - [ ] `tls.connect/read/write/close` via System SSL (GSK APIs).
    - [ ] SAF key ring / PKCS#11 selection (`GSK_KEYRING_FILE`).
- [ ] Wire `luaz_io_dd_register()` into `LUAEXEC` entrypoint init.
  - [ ] `LUAEXEC` must resolve main script from `LUAIN` DD or `DSN=...` (RFC 4.1).
  - [ ] Argument/RC propagation and LUZ-prefixed diagnostics.
  - [ ] Encoding handling per `docs/ENCODING_POLICY.md`.

## 12) Deferred / TBD

- [ ] Define `LUAEXEC` PARM syntax and supported flags.
- [ ] Implement `LUAEXEC` PARM parsing (flags + `DSN=...` + `--` args).
- [ ] Implement optional `LUACFG` parsing (`key=value` per line).

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
- [~] Define and document z/OS batch testing standard (UT/IT/RT JCL).
- [x] Add dedicated MF JCL “unit test” jobs for host runtime helpers (e.g., HASHCMP, LUAPATH).
  - [~] Add Lua integration tests (`tests/integration/lua/`) with IT JCL wrappers.
  - [ ] Each Lua integration test must validate LUZ outputs and RCs.

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
- [x] Add LUAPATH stub searcher in `lua-vm/src/loadlib.c`.
- [x] Restrict os.execute/remove/rename in `lua-vm/src/loslib.c`.
- [x] Restrict os.tmpname in `lua-vm/src/loslib.c`.
- [x] Disable C module searchers in `lua-vm/src/loadlib.c`.
- [x] Restrict os.exit in `lua-vm/src/loslib.c`.
- [x] Add z/OS time backend hooks in `lua-vm/src/loslib.c`.
- [x] Proxy os.execute/remove/rename/tmpname/exit to `tso`/`ds` in `lua-vm/src/loslib.c`.
- [x] Add policy‑proxy for os.getenv/os.setlocale in `lua-vm/src/loslib.c`.
- [x] Add z/OS hook for os.clock in `lua-vm/src/loslib.c`.
- [x] Implement LUAPATH mapping with LUAMAP in `lua-vm/src/loadlib.c` and DDNAME backend.
