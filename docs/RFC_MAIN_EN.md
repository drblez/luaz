# RFC: Lua/TSO — scripting platform for z/OS

Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)

## 0. Status

Draft (v3). License: Apache-2.0.

---

## 1. Purpose and scope

### 1.1. Primary goal

The Lua/TSO platform is intended to replace “system REXX” as the system automation language on z/OS under these conditions:

* execution and debugging must be possible **without interactive TSO**, only via **JCL**;
* ISPF is needed **without panels**, but with access to services;
* integration with **AXR (System REXX)** is required.

### 1.2. Constraints

* **OMVS/USS is not available** → scripts/modules/configs live in **datasets (PS/PDS/PDSE)**, accessed via **DDNAME**.
* Cannot rely on OpenSSL from USS.

---

## 2. Execution model

### 2.1. Batch launch via TMP (IKJEFT01)

The platform must support batch execution via the TSO Terminal Monitor Program with commands supplied through `SYSTSIN`. ([IBM][1])

### 2.2. ISPF in batch via ISPSTART

To use ISPF services, the platform must support “ISPF in batch”: `IKJEFT01` + ISPF dataset allocations + `ISPSTART` to establish the ISPF environment. ([IBM][2])

### 2.3. Foreground TSO

If available, the platform may provide a TSO command processor `LUA`, but this is not required.

---

## 3. Architecture

### 3.1. Components

1. **LUAEXEC (C Core, load module)**
   Lua VM + loader + host API: `tso`, `ds`, `ispf`, `axr` (opt.), `tls`, `crypto` (opt.).

2. **Runtime libraries (Lua modules in PDS/PDSE)**
   `tso.lua`, `ds.lua`, `ispf.lua`, `tls.lua`, `crypto.lua`, `rexxlike.lua`, utilities (parse/stack/…).

3. **Policy/Config (datasets)**
   Whitelists of commands, encoding modes, TLS/crypto policy, limits.

---

## 4. Loading scripts and modules without OMVS

### 4.1. Sources

The platform must be able to read the main script:

* from a PDS/PDSE member (`HLQ.LUA.APP(MYJOB)`), or
* from a DDNAME (`LUAIN`).

### 4.1.1. `LUAEXEC` Parameters

`LUAEXEC` accepts startup parameters and script arguments via:

1) **PARM=** (primary for batch).
   - Short flags/args within PARM length limits.
2) **LUAIN DD** (main script per RFC 4.1).
3) **LUACFG DD** (optional config file).
   - Format: `key=value`, one entry per line.
   - Example keys: `encoding`, `luapath`, `loglevel`.
4) **DSN=...** (explicit script path in PARM).

Rules:
* If `DSN=...` is provided, it takes priority over `LUAIN`.
* Arguments after `--` are passed to the Lua script as‑is.
* Parameter errors must use LUZ‑coded diagnostics.

### 4.2. `require`

`require` must search modules in the `LUAPATH` concatenation (PDS/PDSE) in the specified order.

---

## 5. ISPF without panels

### 5.1. Requirement

The platform must provide ISPF services without panels (no `DISPLAY PANEL(...)`/TBDISPL), including:

* variable pool: `VDEFINE/VGET/VPUT/VRESET/...`
* LM services: `LMINIT/LMOPEN/LMGET/LMFREE/...`
* tables: `TBCREATE/TBOPEN/TBADD/TBGET/TBPUT/TBCLOSE/...`
* file tailoring: `FTOPEN/FTINCL/FTCLOSE/...`
* `LIBDEF`.

### 5.2. Interface

The platform must provide:

* `ispf.exec(cmdline)` — generic ISPF command invocation (ISPEXEC format string),
* `ispf.qry()` — check whether the ISPF environment is up.

(Batch ISPF startup — see section 2.2.) ([IBM][2])

---

## 6. AXR (System REXX) integration

### 6.1. Mode A (required): AXR → Lua via a REXX gateway

The platform must support the scheme “AXR starts Lua” via one stable REXX exec gateway (e.g., `LUAXR`) in REXXLIB:

* input: Lua script name (DSN(member)) + args,
* action: invoke the `LUAEXEC` load module,
* output: RC back to AXR.

Operator control of AXR (start/status/cancel) is performed by standard System REXX mechanisms.

### 6.2. Mode B (optional): Lua → AXR via AXREXX

If programmatic start/cancel of execs or REXXLIB access is needed, the platform may include `axr.*`, implemented via the **AXREXX** service (`REQUEST=EXECUTE|CANCEL|GETREXXLIB`). ([IBM][3])

---

## 7. Host API (minimum specification)

### 7.1. `tso`

Must provide:

* `tso.cmd(cmd, capture?) -> rc, lines[]`
* `tso.alloc(spec) -> rc`, `tso.free(spec) -> rc`
* `tso.msg(text, level?)`
* `tso.exit(rc)`

### 7.2. `ds`

Must provide:

* `ds.open_dd(ddname, {mode="r|w|a"}) -> handle`
* `handle:readline()` / `handle:lines()` / `handle:writeline()` / `handle:close()`

### 7.3. `ispf`

Must provide:

* `ispf.qry()`
* `ispf.exec(cmdline)`
* `ispf.vget(names, opts)`, `ispf.vput(map, opts)`
* basic wrappers for LM/TB/FT.

### 7.4. `tls` (required module when TLS is required)

Must provide:

* `tls.connect{host,port,profile=...} -> conn`
* `conn:read(n)` / `conn:write(buf)` / `conn:close()`
* `conn:peer_cert()` (minimum: subject/issuer/serial/algorithms, as a structure/strings)

Recommended:

* server mode (`tls.listen/accept`) — if inbound TLS connections are needed.

---

## 8. Encodings (EBCDIC)

The platform must correctly handle EBCDIC for input/output (conversion of script sources and output messages is set by config).

---

## 9. TLS/SSL and cryptography without OpenSSL/USS (System SSL as the primary path)

### 9.1. Primary path: z/OS System SSL (GSK APIs) inside C Core

TLS in Lua/TSO must be implemented via **z/OS System SSL** as the primary mechanism (not via OpenSSL). System SSL is a component of z/OS Cryptographic Services and includes APIs and utilities/services for certificate management. ([IBM][4])

Practical requirements:

* `tls.*` is implemented in the C Core via GSK APIs (init, attribute setup, handshake, read/write).
* Key/cert storage: prefer **SAF key ring** or **z/OS PKCS #11 token** (does not require USS files). When building the application, the key database / PKCS#12 / PKCS#11 token / SAF key ring name must match `GSK_KEYRING_FILE`, set via `gsk_attribute_set_buffer()`. ([IBM][5])
* If “OpenSSL-like” handling of certs/containers is required, the platform may use **CMS (Certificate Management Services) API** from System SSL (System SSL docs include a CMS API reference). ([IBM][6])

### 9.2. AT-TLS (additional/alternative deployment mode)

The platform should allow a deployment where TLS is provided by **Application Transparent TLS (AT-TLS)** at the TCP/IP stack level via Policy Agent (PAGENT), while the application works over plain sockets. PAGENT operates within the stack and selects policy by rules. ([IBM][7])
AT-TLS depends on System SSL currency (for example, some scenarios require GSKSRVR). ([IBM][8])

The role of AT-TLS in this RFC: to ease TLS adoption without changing application logic, but **not to replace** System SSL as the baseline TLS implementation in the product.

### 9.3. Crypto primitives and “other OpenSSL stuff”

For hashes/HMAC/signatures/PKCS#11 the platform preferably uses **ICSF** (z/OS Integrated Cryptographic Service Facility), which works with hardware crypto and RACF and provides APIs for crypto services. ([IBM][9])

---

## 10. Testing and observability (JCL-only)

### 10.1. Harness

The platform must ship with a test runner that returns RC≠0 on failure and writes results to SYSOUT/datasets.

### 10.2. C Core coverage

If C coverage is needed without USS, **z/OS Debugger Code Coverage** is recommended; it supports unattended batch runs and emits data/reports (including XML). ([IBM][10])

---

## 11. Security and policy

### 11.1. Policy

The platform must have a config-policy (dataset) that defines:

* whitelist/blacklist for `tso.cmd`,
* enable/disable `axr`, `crypto`, trace levels,
* output/resource limits.

---

## 12. Packaging: datasets and DDNAME (recommended profile)

* `HLQ.LUA.LOAD` — load modules (`LUAEXEC`, …)
* `HLQ.LUA.LIB` — runtime Lua modules
* `HLQ.LUA.APP` — application scripts
* `HLQ.LUA.TEST` — tests/fixtures
* `HLQ.LUA.CONF` — configs/policy

DDNAME:

* `STEPLIB` → `HLQ.LUA.LOAD`
* `LUAPATH` → concat (`HLQ.LUA.CONF`, `HLQ.LUA.LIB`, `HLQ.LUA.APP`, …)
* `LUACONF` → config/policy member
* (opt.) `LUAIN`, `LUAOUT`

---

## 13. MVP

MVP must include:

1. batch launch via IKJEFT01/SYSTSIN ([IBM][1])
2. `tso.cmd` with output capture
3. `ds.open_dd` streaming read/write
4. `require` from `LUAPATH`
5. ISPF without panels: `ispf.qry`, `ispf.exec`, `ispf.vget/vput` + minimum LM (via ISPF in batch) ([IBM][2])
6. AXR mode A: REXX gateway `LUAXR`
7. TLS: `tls.connect/read/write/close` based on **System SSL** + SAF key ring / PKCS#11 token support ([IBM][4])

---

## 14. “Replaced system REXX” criterion

Achieved when:

* typical system REXX scenarios (ALLOC/read/write datasets/output capture/ISPF services without panels) are implemented in Lua/TSO in JCL-only mode;
* AXR remains the entry point (via a single `LUAXR`);
* TLS is provided via System SSL as the standard mechanism, without dependency on OpenSSL/USS. ([IBM][4])

[1]: https://www.ibm.com/docs/en/zos/3.1.0?topic=environment-sample-batch-job&utm_source=chatgpt.com "Sample batch job"
[2]: https://www.ibm.com/support/pages/how-use-ispf-batch?utm_source=chatgpt.com "How to use ISPF in batch"
[3]: https://www.ibm.com/docs/en/zos/2.5.0?topic=dyn-axrexx-system-rexx-services&utm_source=chatgpt.com "AXREXX - System REXX services"
[4]: https://www.ibm.com/docs/en/SSLTBW_3.1.0/pdf/gska100_v3r1.pdf?utm_source=chatgpt.com "z/OS System SSL Programming"
[5]: https://www.ibm.com/docs/en/zos/2.5.0?topic=application-building-zos-system-ssl&utm_source=chatgpt.com "Building a z/OS System SSL application"
[6]: https://www.ibm.com/docs/SSLTBW_3.2.0/pdf/gska100_v3r2.pdf?utm_source=chatgpt.com "z/OS System SSL Programming"
[7]: https://www.ibm.com/docs/en/zos/2.5.0?topic=enabler-tls-usage-overview&utm_source=chatgpt.com "AT-TLS usage overview"
[8]: https://www.ibm.com/docs/en/zos/3.1.0?topic=security-tls-currency-system-ssl&utm_source=chatgpt.com "Using AT-TLS currency with System SSL"
[9]: https://www.ibm.com/docs/en/zos/3.1.0?topic=services-zos-cryptographic-icsf-overview&utm_source=chatgpt.com "Abstract for z/OS Integrated Cryptographic Service Facility ..."
[10]: https://www.ibm.com/docs/en/developer-for-zos/16.0?topic=coverage-introduction-zos-debugger-code&utm_source=chatgpt.com "Introduction to z/OS Debugger Code Coverage"
