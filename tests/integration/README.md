# Integration Tests (Lua/TSO)

## Purpose

Integration tests validate Lua‑level behavior of z/OS‑specific modules
and their interaction with datasets and JCL in batch mode.

## Scope

- `tso` module (cmd/alloc/free/msg/exit).
- `ds` module (open_dd/open_dsn/member/info).
- `ispf` module (exec/qry/vget/vput/LM/TB/FT/LIBDEF).
- `axr` gateway (LUAXR -> LUAEXEC).
- `tls` (System SSL, if enabled).

## Layout

- `tests/integration/lua/` — Lua test scripts.
- `jcl/IT_*.jcl` — JCL jobs that run integration tests.
- `docs/tests/IT_*.md` — test descriptions and expected RC.

## Rules

- **One test = one JCL job** (`IT_*.jcl`).
- Tests must be **batch‑safe** and **idempotent** (create/clean datasets).
- Each test must validate **return codes** and **expected output**.
- All user‑visible output must use `LUZ‑NNNNN` prefixes.
- Lua scripts should **exit non‑zero** on failure.

## Required Checks (Lua)

- `tso.cmd` returns RC and captures output.
- `tso.alloc/free` create and release DD allocations.
- `tso.msg` emits LUZ‑prefixed output.
- `tso.exit` terminates with requested RC.
- `ds.open_dd/open_dsn` read/write paths work end‑to‑end.

## Required Checks (JCL)

- Each job validates RC and stops on unexpected RC (`COND`/`IF`).
- Job output contains the expected LUZ codes.
