# Development Workflow (z/OS)

HLQ used in examples: `DRBLEZ`.

## 1) Upload Sources

- C sources -> `DRBLEZ.LUA.SRC`
- Lua modules -> `DRBLEZ.LUA.LIB`
- JCL -> `DRBLEZ.LUA.JCL`

## 2) Build LUAEXEC

- Run the incremental build job in `DRBLEZ.LUA.JCL(SUBBUILD)`.
- Output load module: `DRBLEZ.LUA.LOAD(LUAEXEC)`.

## 3) Runtime Allocations

- `STEPLIB` -> `DRBLEZ.LUA.LOAD`
- `LUAPATH` -> concat of PDS/PDSE with modules + `LUAMAP`
- `LUACONF` -> `DRBLEZ.LUA.CONF(LUACONF)`
- `LUAIN` -> `DRBLEZ.LUA.APP(MAIN)` (optional)

## 4) Run (Batch)

- Use IKJEFT01 with `SYSTSIN` to invoke LUAEXEC.
- For ISPF services, use ISPSTART with proper ISPF dataset allocations.

## 5) LUAEXEC PARM (current)

- `MODE=TSO` or `MODE=PGM` (default: `PGM`).
- `DSN=...` detected but not implemented yet.
- `--` ends control parsing; tokens after it become Lua `arg[]`.
