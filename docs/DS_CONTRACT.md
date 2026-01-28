# DS Module Contract (z/OS)

## Scope

`ds.open_dd` provides streaming access to DDNAME-allocated datasets. `ds.open_dsn` opens fully-qualified MVS dataset names directly. This is the minimal dataset I/O API for Lua/TSO in batch. Only datasets are supported (no USS paths).

## API

- `ds.open_dd(ddname, {mode="r|w|a"}) -> handle`
- `ds.open_dd(ddname, "r|w|a") -> handle`
- `ds.open_dsn(dsn, {mode="r|w|a"}) -> handle`
- `ds.open_dsn(dsn, "r|w|a") -> handle`
- `ds.member(dsn, member) -> "dsn(member)"`
- `ds.remove(dsn) -> true`
- `ds.rename(old_dsn, new_dsn) -> true`
- `ds.tmpname() -> dsn`
- `ds.info(dsn) -> table`
- `handle:readline()` / `handle:lines()` / `handle:writeline()` / `handle:close()`

## C Host API

- `int lua_ds_open_dd(const char *ddname, const char *mode, struct lua_ds_handle **out)`
- `int lua_ds_open_dsn(const char *dsn, const char *mode, struct lua_ds_handle **out)`
- `int lua_ds_read(struct lua_ds_handle *h, void *buf, unsigned long *len)`
- `int lua_ds_write(struct lua_ds_handle *h, const void *buf, unsigned long len)`
- `int lua_ds_close(struct lua_ds_handle *h)`

## Mode Semantics

- `r` — open DDNAME for reading.
- `w` — open DDNAME for writing (truncate).
- `a` — open DDNAME for append.

## DSN Semantics

- `ds.open_dsn` expects a fully-qualified data set name and opens it using the MVS `//'<dsn>'` path syntax.
- If the input already starts with `//` it is passed through unchanged; if it already contains quotes, `//` is prefixed.

## Member Semantics

- `ds.member` expects a plain DSN and member name and returns the combined `dsn(member)` string.
- The returned value is intended for `ds.open_dsn` calls.

## Remove/Rename Semantics

- `ds.remove` deletes the dataset named by `dsn` using C runtime file naming (`//'<dsn>'`).
- `ds.rename` renames `old_dsn` to `new_dsn` using C runtime file naming (`//'<dsn>'`).

## Tmpname Semantics

- `ds.tmpname` returns a dataset name in the form `SYSUID.LUAZ.TMP.TXXXXXXX`.
- The returned name is **not allocated**; callers must allocate it before use.

## Info Semantics

- `ds.info` opens the dataset by DSN and returns a table:
  - `dsname` (string, when available)
  - `filename` (string, from `fldata()`; often `dd:DDNAME` or `*`)
  - `recfm` (string, e.g. `FB`)
  - `dsorg` (string, e.g. `PS`/`PO`/`PDSE`)
  - `lrecl` (number; from `__maxreclen`)
  - `blksize` (number)
  - `recfm_flags` / `dsorg_flags` (tables of booleans)

## Line Semantics

- `handle:writeline()` appends `\\n` when the input line does not end with it.

## Error Semantics

- On failure, functions return `nil`, an LUZ-prefixed message, and a numeric code.
- `handle:readline()` returns `nil` at EOF.

## Errors

- `LUZ30006` — open failed.
- `LUZ30007` — read failed or invalid handle/mode.
- `LUZ30008` — write failed or invalid handle/mode.
- `LUZ30009` — close failed or invalid handle.
- `LUZ30026` — remove failed or invalid input.
- `LUZ30027` — rename failed or invalid input.
- `LUZ30029` — member format invalid.
- `LUZ30037` — info failed.
