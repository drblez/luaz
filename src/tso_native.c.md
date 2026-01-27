# IBM References for src/tso_native.c

## ikjtsoev-os-linkage

Source: IBM z/OS 2.4 XL C/C++ documentation, "#pragma linkage (C only)".

- URL: https://www.ibm.com/docs/en/zos/2.4.0?topic=descriptions-pragma-linkage-c-only
- Relevant points:
  - `#pragma linkage(identifier, OS)` assigns OS linkage calling convention.
  - The `identifier` may be a function name **or a typedef name** used for
    entry point declarations, which allows OS linkage to be applied to
    function pointer types.

This is used to declare `ikjtsoev_fn` with OS linkage so the C call builds
an OS-style parameter list when invoking `IKJTSOEV` via `fetch()`.
