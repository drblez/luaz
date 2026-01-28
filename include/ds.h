/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO dataset API (DDNAME/DSN I/O).
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | lua_ds_open_dd | function | Open DDNAME stream with mode |
 * | lua_ds_open_dsn | function | Open DSN stream with mode |
 * | lua_ds_read | function | Read from DDNAME stream |
 * | lua_ds_write | function | Write to DDNAME stream |
 * | lua_ds_close | function | Close DDNAME stream |
 */
#ifndef DS_H
#define DS_H

#ifdef __cplusplus
extern "C" {
#endif

struct lua_ds_handle;

/**
 * @brief Open a DDNAME stream with the specified mode.
 *
 * @param ddname DDNAME string (1..8 chars).
 * @param mode Mode string ("r", "w", or "a").
 * @param out Output handle pointer.
 * @return 0 on success, or LUZ_E_DS_OPEN on failure.
 */
int lua_ds_open_dd(const char *ddname, const char *mode, struct lua_ds_handle **out);
/**
 * @brief Open a DSN stream with the specified mode.
 *
 * @param dsn Data set name string (fully-qualified).
 * @param mode Mode string ("r", "w", or "a").
 * @param out Output handle pointer.
 * @return 0 on success, or LUZ_E_DS_OPEN on failure.
 */
int lua_ds_open_dsn(const char *dsn, const char *mode, struct lua_ds_handle **out);
/**
 * @brief Read bytes from a DDNAME stream.
 *
 * @param h DS handle.
 * @param buf Output buffer.
 * @param len In/out: capacity on input, bytes read on output.
 * @return 0 on success, or LUZ_E_DS_READ on failure.
 */
int lua_ds_read(struct lua_ds_handle *h, void *buf, unsigned long *len);
/**
 * @brief Write bytes to a DDNAME stream.
 *
 * @param h DS handle.
 * @param buf Input buffer.
 * @param len Number of bytes to write.
 * @return 0 on success, or LUZ_E_DS_WRITE on failure.
 */
int lua_ds_write(struct lua_ds_handle *h, const void *buf, unsigned long len);
/**
 * @brief Close a DDNAME stream and free the handle.
 *
 * @param h DS handle.
 * @return 0 on success, or LUZ_E_DS_CLOSE on failure.
 */
int lua_ds_close(struct lua_ds_handle *h);

#ifdef __cplusplus
}
#endif

#endif /* DS_H */
