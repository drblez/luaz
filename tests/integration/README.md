# Integration Tests (Lua/TSO)

## Purpose

Integration tests validate Lua‑level behavior of z/OS‑specific modules
and their interaction with datasets and JCL in batch mode.

## Scope

- `tso` module (cmd/msg/exit).
- `ds` module (open_dd/open_dsn/member/info).
- `ispf` module (exec/qry/vget/vput/LM/TB/FT/LIBDEF).
- `axr` gateway (LUAXR -> LUAEXEC).
- `tls` (System SSL, if enabled).
- LUACFG runtime configuration exposure (LUAZ_CONFIG).

## Layout

- `tests/integration/lua/` — Lua test scripts.
- `jcl/IT_*.jcl` — JCL jobs that run integration tests.
- `docs/tests/IT_*.md` — test descriptions and expected RC.

## Rules

- **One test = one JCL job** (`IT_*.jcl`).
- Tests must be **batch‑safe** and **idempotent** (create/clean datasets).
- Each test must validate **error objects** and **expected output**.
- All user‑visible output must use `LUZNNNNN` prefixes.
- Lua scripts should **exit non‑zero** on failure.

## Required Checks (Lua)

- `tso.cmd(..., true)` returns output lines and `err` is nil on success.
- `tso.cmd(..., true)` output lines are prefixed with `LUZ30031` and printed to LUAOUT; Lua stdout prints `LUZ00022` and `LUZ00023` in LUAOUT.
- `LUAZ_CONFIG` is present and matches LUACFG values (see IT_TSO, IT_LUACFG).
-- `tso.alloc/free` are out of scope until direct TSO allocation is implemented.
- `tso.msg` emits LUZ‑prefixed output.
- `tso.exit` terminates with requested RC.
- `ds.open_dd/open_dsn` read/write paths work end‑to‑end.

## Required Checks (JCL)

- Each job validates RC and stops on unexpected RC (`COND`/`IF`).
- Job output contains the expected LUZ codes.
