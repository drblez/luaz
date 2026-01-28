/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO policy/config access.
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
 *
 * Platform Requirements:
 * - LE: required (C runtime).
 * - AMODE: 31-bit.
 * - EBCDIC: policy content is interpreted as EBCDIC text.
 * - DDNAME I/O: LUACFG DDNAME provides config text (DD:LUACFG).
 */
#include "ERRORS"
#include "POLICY"

#include <stdio.h>
#include <string.h>
#include <ctype.h>

#define POLICY_MAX_VALUE 1024u
#define POLICY_MAX_LINE 1024u

typedef struct luaz_policy_entry {
  const char *key;
  char value[POLICY_MAX_VALUE];
  int set;
} luaz_policy_entry;

static luaz_policy_entry g_policy[] = {
  {"allow.tso.cmd", "", 0},
  {"tso.cmd.whitelist", "", 0},
  {"tso.cmd.blacklist", "", 0},
  {"trace.level", "", 0},
  {"limits.output.lines", "", 0},
  {"tso.cmd.capture.default", "", 0},
  {"tso.rexx.exec", "", 0},
  {"tso.rexx.dd", "", 0},
  {"luapath.dd", "", 0},
  {"luain.dd", "", 0},
  {"luaout.dd", "", 0},
  {"luaconf.member", "", 0},
  {"tls.keyring", "", 0},
  {"tls.pkcs11.token", "", 0},
  {"tls.profile", "", 0}
};

static int g_policy_loaded = 0;

/**
 * @brief Case-insensitive string compare for policy keys/values.
 *
 * @param a First string.
 * @param b Second string.
 * @return 0 when equal, nonzero otherwise.
 */
static int policy_stricmp(const char *a, const char *b)
{
  unsigned char ca;
  unsigned char cb;

  if (a == NULL || b == NULL)
    return (a == b) ? 0 : 1;
  while (*a && *b) {
    ca = (unsigned char)tolower((unsigned char)*a++);
    cb = (unsigned char)tolower((unsigned char)*b++);
    if (ca != cb)
      return (int)ca - (int)cb;
  }
  return (int)tolower((unsigned char)*a) - (int)tolower((unsigned char)*b);
}

/**
 * @brief Trim leading/trailing whitespace in place.
 *
 * @param s Input string buffer.
 * @return Pointer to trimmed string (may be inside original buffer).
 */
static char *policy_trim(char *s)
{
  char *end;

  if (s == NULL)
    return NULL;
  while (*s != '\0' && isspace((unsigned char)*s))
    s++;
  if (*s == '\0')
    return s;
  end = s + strlen(s) - 1;
  while (end > s && isspace((unsigned char)*end))
    end--;
  end[1] = '\0';
  return s;
}

/**
 * @brief Find a policy key index by name.
 *
 * @param key Policy key string.
 * @return Index on success, or -1 if not found.
 */
static int policy_key_index(const char *key)
{
  size_t i;

  if (key == NULL)
    return -1;
  for (i = 0; i < (sizeof(g_policy) / sizeof(g_policy[0])); i++) {
    if (policy_stricmp(key, g_policy[i].key) == 0)
      return (int)i;
  }
  return -1;
}

/**
 * @brief Reset all policy entries to an unset state.
 *
 * @return None.
 */
static void policy_reset(void)
{
  size_t i;

  for (i = 0; i < (sizeof(g_policy) / sizeof(g_policy[0])); i++) {
    g_policy[i].set = 0;
    g_policy[i].value[0] = '\0';
  }
  g_policy_loaded = 0;
}

/**
 * @brief Validate a DDNAME/token value (1-8 chars, A-Z0-9@#$).
 *
 * @param value Input string.
 * @return 1 if valid, 0 otherwise.
 */
static int policy_is_ddname(const char *value)
{
  size_t len = 0;

  if (value == NULL || value[0] == '\0')
    return 0;
  for (; value[len] != '\0'; len++) {
    unsigned char c = (unsigned char)value[len];
    if (!(isalnum(c) || c == '@' || c == '#' || c == '$'))
      return 0;
  }
  if (len == 0 || len > 8)
    return 0;
  return 1;
}

/**
 * @brief Validate a boolean literal.
 *
 * @param value Input string.
 * @return 1 if valid, 0 otherwise.
 */
static int policy_is_bool(const char *value)
{
  if (value == NULL)
    return 0;
  if (policy_stricmp(value, "true") == 0 ||
      policy_stricmp(value, "false") == 0 ||
      policy_stricmp(value, "1") == 0 ||
      policy_stricmp(value, "0") == 0)
    return 1;
  return 0;
}

/**
 * @brief Validate trace level literal.
 *
 * @param value Input string.
 * @return 1 if valid, 0 otherwise.
 */
static int policy_is_trace_level(const char *value)
{
  if (value == NULL)
    return 0;
  if (policy_stricmp(value, "off") == 0 ||
      policy_stricmp(value, "error") == 0 ||
      policy_stricmp(value, "info") == 0 ||
      policy_stricmp(value, "debug") == 0)
    return 1;
  return 0;
}

/**
 * @brief Map a trace level literal to an ordinal rank.
 *
 * @param value Trace level literal.
 * @return Rank value, or -1 if invalid.
 */
static int policy_trace_rank(const char *value)
{
  if (value == NULL)
    return -1;
  if (policy_stricmp(value, "off") == 0)
    return 0;
  if (policy_stricmp(value, "error") == 0)
    return 1;
  if (policy_stricmp(value, "info") == 0)
    return 2;
  if (policy_stricmp(value, "debug") == 0)
    return 3;
  return -1;
}

/**
 * @brief Validate allowlist/denylist mode literal.
 *
 * @param value Input string.
 * @return 1 if valid, 0 otherwise.
 */
static int policy_is_allow_mode(const char *value)
{
  if (value == NULL)
    return 0;
  if (policy_stricmp(value, "whitelist") == 0 ||
      policy_stricmp(value, "blacklist") == 0)
    return 1;
  return 0;
}

/**
 * @brief Validate a numeric literal.
 *
 * @param value Input string.
 * @return 1 if valid, 0 otherwise.
 */
static int policy_is_number(const char *value)
{
  const char *p = value;

  if (p == NULL || *p == '\0')
    return 0;
  while (*p != '\0') {
    if (!isdigit((unsigned char)*p))
      return 0;
    p++;
  }
  return 1;
}

/**
 * @brief Validate a policy value for a given key.
 *
 * @param key Policy key string.
 * @param value Value string.
 * @return 1 if valid, 0 otherwise.
 */
static int policy_validate_value(const char *key, const char *value)
{
  if (key == NULL || value == NULL)
    return 0;
  if (policy_stricmp(key, "allow.tso.cmd") == 0)
    return policy_is_allow_mode(value);
  if (policy_stricmp(key, "trace.level") == 0)
    return policy_is_trace_level(value);
  if (policy_stricmp(key, "limits.output.lines") == 0)
    return policy_is_number(value);
  if (policy_stricmp(key, "tso.cmd.capture.default") == 0)
    return policy_is_bool(value);
  if (policy_stricmp(key, "tso.rexx.exec") == 0 ||
      policy_stricmp(key, "tso.rexx.dd") == 0 ||
      policy_stricmp(key, "luapath.dd") == 0 ||
      policy_stricmp(key, "luain.dd") == 0 ||
      policy_stricmp(key, "luaout.dd") == 0 ||
      policy_stricmp(key, "luaconf.member") == 0)
    return policy_is_ddname(value);
  return 1;
}

/**
 * @brief Load policy/config data from a DDNAME path (LUACFG).
 *
 * @param path DDNAME path (e.g., "DD:LUACFG").
 * @return 0 on success or when config is absent; nonzero on parse errors.
 *
 * Change note: implement LUACFG parsing and validation.
 * Problem: runtime configuration was not available to Lua/TSO.
 * Expected effect: LUACFG key/value data is loaded for runtime policy.
 * Impact: tso.cmd defaults and policy checks can read config values.
 */
int luaz_policy_load(const char *path)
{
  FILE *fp = NULL;
  char line[POLICY_MAX_LINE];
  int rc = 0;
  int line_no = 0;
  int errors = 0;

  policy_reset();
  if (path == NULL || path[0] == '\0')
    return 0;

  fp = fopen(path, "r");
  if (fp == NULL)
    return 0;

  while (fgets(line, sizeof(line), fp) != NULL) {
    char *p = NULL;
    char *key = NULL;
    char *value = NULL;
    char *eq = NULL;
    size_t len = strlen(line);
    int long_line = 0;
    line_no++;
    if (strchr(line, '\n') == NULL && strchr(line, '\r') == NULL &&
        !feof(fp)) {
      long_line = 1;
    }
    while (len > 0 &&
           (line[len - 1] == '\n' || line[len - 1] == '\r')) {
      line[--len] = '\0';
    }
    if (len == 0)
      continue;
    if (long_line) {
      int c;
      while ((c = fgetc(fp)) != '\n' && c != '\r' && c != EOF)
        ;
      printf("LUZ30093 LUACFG line too long line=%d\n", line_no);
      errors++;
      continue;
    }
    p = policy_trim(line);
    if (p == NULL || p[0] == '\0')
      continue;
    if (p[0] == '#' || p[0] == '*')
      continue;
    eq = strchr(p, '=');
    if (eq == NULL) {
      printf("LUZ30094 LUACFG invalid line=%d\n", line_no);
      errors++;
      continue;
    }
    *eq = '\0';
    key = policy_trim(p);
    value = policy_trim(eq + 1);
    if (key == NULL || key[0] == '\0') {
      printf("LUZ30094 LUACFG invalid line=%d\n", line_no);
      errors++;
      continue;
    }
    rc = policy_key_index(key);
    if (rc < 0) {
      printf("LUZ30095 LUACFG unknown key=%s line=%d\n", key, line_no);
      errors++;
      continue;
    }
    if (!policy_validate_value(key, value)) {
      printf("LUZ30096 LUACFG invalid value key=%s line=%d\n", key, line_no);
      errors++;
      continue;
    }
    if (value == NULL)
      value = "";
    if (strlen(value) >= POLICY_MAX_VALUE) {
      printf("LUZ30097 LUACFG value too long key=%s line=%d\n", key, line_no);
      errors++;
      continue;
    }
    if (g_policy[rc].set) {
      printf("LUZ30098 LUACFG duplicate key=%s\n", key);
    }
    strcpy(g_policy[rc].value, value);
    g_policy[rc].set = 1;
    g_policy_loaded = 1;
  }
  fclose(fp);
  return (errors == 0) ? 0 : LUZ_E_POLICY_GET;
}

/**
 * @brief Read a key value from loaded policy data.
 *
 * @param key Policy key string.
 * @param out Output buffer or NULL to query length only.
 * @param len In/out length: capacity on input, value length on output.
 * @return 0 on success (even if key is missing), or nonzero on errors.
 */
int luaz_policy_get(const char *key, char *out, unsigned long *len)
{
  const char *value = NULL;
  unsigned long cap = 0;
  size_t value_len = 0;

  if (len == NULL) {
    return 0;
  }
  value = luaz_policy_get_raw(key);
  if (value == NULL) {
    *len = 0;
    return 0;
  }
  value_len = strlen(value);
  cap = *len;
  if (out == NULL) {
    *len = (unsigned long)value_len;
    return 0;
  }
  if (cap == 0) {
    *len = (unsigned long)value_len;
    return 0;
  }
  if (cap > 0) {
    unsigned long copy_len = (unsigned long)value_len;
    if (copy_len >= cap)
      copy_len = cap - 1;
    memcpy(out, value, copy_len);
    out[copy_len] = '\0';
  }
  *len = (unsigned long)value_len;
  return 0;
}

/**
 * @brief Get a raw value pointer for a key (no copy).
 *
 * @param key Policy key string.
 * @return Pointer to value string, or NULL if missing.
 */
const char *luaz_policy_get_raw(const char *key)
{
  int idx = policy_key_index(key);

  if (idx < 0)
    return NULL;
  if (!g_policy[idx].set)
    return NULL;
  return g_policy[idx].value;
}

/**
 * @brief Check whether policy data has been loaded.
 *
 * @return 1 if loaded, 0 otherwise.
 */
int luaz_policy_loaded(void)
{
  return g_policy_loaded;
}

/**
 * @brief Return number of known policy keys.
 *
 * @return Count of keys in the registry.
 */
int luaz_policy_key_count(void)
{
  return (int)(sizeof(g_policy) / sizeof(g_policy[0]));
}

/**
 * @brief Return policy key name by index.
 *
 * @param index Key index.
 * @return Key string, or NULL if index is invalid.
 */
const char *luaz_policy_key_name(int index)
{
  if (index < 0 || index >= (int)(sizeof(g_policy) / sizeof(g_policy[0])))
    return NULL;
  return g_policy[index].key;
}

/**
 * @brief Return policy value by index.
 *
 * @param index Key index.
 * @return Value string, or NULL if not set.
 */
const char *luaz_policy_value_name(int index)
{
  if (index < 0 || index >= (int)(sizeof(g_policy) / sizeof(g_policy[0])))
    return NULL;
  if (!g_policy[index].set)
    return NULL;
  return g_policy[index].value;
}

/**
 * @brief Check whether a given trace level is enabled by policy.
 *
 * @param level Trace level string (error/info/debug).
 * @return 1 if enabled, 0 otherwise.
 *
 * Change note: add trace-level helper for diagnostics gating.
 * Problem: debug prints were unconditional in LUACMD/LUAEXRUN paths.
 * Expected effect: trace.level controls diagnostic verbosity centrally.
 * Impact: LUZ3007x diagnostics are emitted only when enabled.
 */
int luaz_policy_trace_enabled(const char *level)
{
  const char *cfg = NULL;
  int cfg_rank = -1;
  int req_rank = -1;

  req_rank = policy_trace_rank(level);
  if (req_rank < 0)
    return 0;
  cfg = luaz_policy_get_raw("trace.level");
  if (cfg == NULL || cfg[0] == '\0')
    return 0;
  cfg_rank = policy_trace_rank(cfg);
  if (cfg_rank < 0)
    return 0;
  return (cfg_rank >= req_rank) ? 1 : 0;
}
