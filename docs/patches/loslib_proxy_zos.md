# Patch: loslib z/OS proxy to host APIs

## Why

Lua/TSO should route OS operations to host APIs instead of disabling them outright. This preserves usability while honoring z/OS constraints.

## What changes

- `lua-vm/src/loslib.c`: under `LUAZ_ZOS`, proxy `os.execute`, `os.remove`, `os.rename`, `os.tmpname`, `os.exit` to `tso`/`ds` modules if available.
- If required module/function is missing, return LUZ‑coded error.

## Expected effect

- OS operations are delegated to host APIs (TSO or dataset services).
- Clear LUZ errors if modules are not present or not preloaded.

## How to verify

- With `LUAZ_ZOS` and `tso` module loaded, `os.execute("LISTCAT")` calls `tso.cmd`.
- With `LUAZ_ZOS` and `ds` module loaded, `os.remove("HLQ.DATA")` calls `ds.remove`.
- If modules are missing, errors include `LUZ-44010`/`LUZ-44011`.
