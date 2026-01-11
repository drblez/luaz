# Test Plan (Draft)

## Goals

- Verify Lua/TSO core behavior in z/OS batch and TSO/ISPF contexts.
- Ensure dataset I/O and host APIs behave deterministically.

## Test Categories

- Unit tests: core Lua hooks and platform abstraction boundaries.
- Integration tests: TSO command execution, dataset reads/writes, ISPF services.
- Regression tests: known scenarios from System REXX workflows.

## Execution Requirements

- Tests must run in batch mode and return RC≠0 on failure.
- Provide JCL wrappers for each major test suite.

## Naming & Layout

- `tests/unit/`, `tests/integration/`, `tests/regression/`
- JCL wrappers in `jcl/` with clear DDNAME inputs/outputs.
