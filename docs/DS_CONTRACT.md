# DS Module Contract (z/OS)

## Scope

`ds.open_dd` provides streaming access to DDNAME-allocated datasets. This is the minimal dataset I/O API for Lua/TSO in batch. Only datasets allocated to DDNAME are supported (no USS paths).

## API

- `ds.open_dd(ddname, {mode="r|w|a"}) -> handle`
- `handle:readline()` / `handle:lines()` / `handle:writeline()` / `handle:close()`

## C Host API

- `int lua_ds_open_dd(const char *ddname, const char *mode, struct lua_ds_handle **out)`
- `int lua_ds_read(struct lua_ds_handle *h, void *buf, unsigned long *len)`
- `int lua_ds_write(struct lua_ds_handle *h, const void *buf, unsigned long len)`
- `int lua_ds_close(struct lua_ds_handle *h)`

## Mode Semantics

- `r` — open DDNAME for reading.
- `w` — open DDNAME for writing (truncate).
- `a` — open DDNAME for append.

## Errors

- `LUZ30006` — open failed.
- `LUZ30007` — read failed or invalid handle/mode.
- `LUZ30008` — write failed or invalid handle/mode.
- `LUZ30009` — close failed or invalid handle.
