/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO policy/config access stubs.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | luaz_policy_load | function | Load policy/config from LUACFG DD |
 * | luaz_policy_get | function | Read key from loaded policy data |
 * | luaz_policy_get_raw | function | Get raw value pointer for key |
 * | luaz_policy_loaded | function | Report whether policy data is loaded |
 * | luaz_policy_key_count | function | Return number of known policy keys |
 * | luaz_policy_key_name | function | Get policy key name by index |
 * | luaz_policy_value_name | function | Get policy value by index |
 * | luaz_policy_trace_enabled | function | Check if trace level enables a message |
 */
#ifndef POLICY_H
#define POLICY_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Load policy/config data from a DDNAME path (LUACFG).
 *
 * @param path DDNAME path (e.g., "DD:LUACFG").
 * @return 0 on success or when no config is present; nonzero on parse errors.
 */
int luaz_policy_load(const char *path);

/**
 * @brief Read a key value from loaded policy data.
 *
 * @param key Policy key string.
 * @param out Output buffer or NULL to query length only.
 * @param len In/out length: capacity on input, value length on output.
 * @return 0 on success (even if key is missing), or nonzero on errors.
 */
int luaz_policy_get(const char *key, char *out, unsigned long *len);

/**
 * @brief Get a raw value pointer for a key (no copy).
 *
 * @param key Policy key string.
 * @return Pointer to value string, or NULL if missing.
 */
const char *luaz_policy_get_raw(const char *key);

/**
 * @brief Check whether policy data has been loaded.
 *
 * @return 1 if loaded, 0 otherwise.
 */
int luaz_policy_loaded(void);

/**
 * @brief Return number of known policy keys.
 *
 * @return Count of keys in the registry.
 */
int luaz_policy_key_count(void);

/**
 * @brief Return policy key name by index.
 *
 * @param index Key index.
 * @return Key string, or NULL if index is invalid.
 */
const char *luaz_policy_key_name(int index);

/**
 * @brief Return policy value by index.
 *
 * @param index Key index.
 * @return Value string, or NULL if not set.
 */
const char *luaz_policy_value_name(int index);
/**
 * @brief Check whether a given trace level is enabled by policy.
 *
 * @param level Trace level string (error/info/debug).
 * @return 1 if enabled, 0 otherwise.
 */
int luaz_policy_trace_enabled(const char *level);

#ifdef __cplusplus
}
#endif

#endif /* POLICY_H */
