# Test Guidelines (z/OS Batch)

## Purpose

This document defines a single, consistent testing workflow for Lua/TSO on z/OS.
All tests are batch‑friendly and validate return codes explicitly.

## Test Levels

- **UT** (unit): single utility or function, minimal dependencies.
- **IT** (integration): module + required supporting components.
- **RT** (regression): scenario tied to a bug fix or behavioral change.

## File Layout

- `jcl/UT_*.jcl` — unit tests (one job per test).
- `jcl/IT_*.jcl` — integration tests.
- `jcl/RT_*.jcl` — regression tests.
- `docs/tests/` — test descriptions (goal, steps, expected RC).
- `tests/data/` — input datasets or fixtures (if needed).
 - Example: `docs/tests/UT_TSOAF.md` describes `jcl/UTTSOAF.jcl`.

## Job Rules

- **One test = one job.**
- **Idempotent:** a test must clean/create its own datasets and be re‑runnable.
- **Fail‑fast:** use `COND`/`IF` to stop on unexpected RC.
- **RC discipline:** every step has an expected RC; document it in the test README.
- **Isolation:** test datasets must not overlap with build or runtime datasets.

## Naming

- `UT_<module>.jcl` — e.g. `UT_HASHCMP.jcl`
- `IT_<feature>.jcl` — e.g. `IT_REQUIRE_DD.jcl`
- `RT_<ticket>.jcl` — e.g. `RT_001_OS_DATE.jcl`

## Execution Policy

- Run **UT** tests before every commit.
- Run **IT** tests before any release or integration milestone.
- Before running any **IT** job, execute the incremental build (`jcl/BUILDINC.jcl`).
- Run **RT** tests when a related bug fix is changed or refactored.

## Documentation Template

Each test must have a short README in `docs/tests/`:

- **Purpose**
- **Preconditions**
- **Steps**
- **Expected RC per step**
- **Artifacts produced**
