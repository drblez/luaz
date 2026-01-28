/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * LUACFG unit test driver for policy parsing/validation.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | lua_tso_ut_expect_value | function | Validate policy key value against expected text |
 * | lua_tso_ut_expect_missing | function | Validate policy key is missing |
 * | main | function | Load LUACFG and assert parsed policy values |
 *
 * Platform Requirements:
 * - LE: required (C runtime).
 * - AMODE: 31-bit.
 * - EBCDIC: config text and literals are interpreted as EBCDIC after sync.
 * - DDNAME I/O: LUACFG DDNAME provides config text (DD:LUACFG).
 */
#include "POLICY"

#include <stdio.h>
#include <string.h>

/**
 * @brief Validate that a policy key equals the expected value.
 *
 * @param key Policy key string.
 * @param expected Expected value string.
 * @param failures Failure counter to increment on mismatch.
 * @return 0 when value matches, 1 when missing or mismatched.
 */
static int lua_tso_ut_expect_value(const char *key, const char *expected, int *failures)
{
  const char *value = NULL;

  value = luaz_policy_get_raw(key);
  if (value == NULL) {
    printf("LUZ00041 LUACFG UT missing key=%s\n", key);
    if (failures != NULL)
      (*failures)++;
    return 1;
  }
  if (expected == NULL)
    expected = "";
  if (strcmp(value, expected) != 0) {
    printf("LUZ00041 LUACFG UT mismatch key=%s value=%s expected=%s\n",
           key, value, expected);
    if (failures != NULL)
      (*failures)++;
    return 1;
  }
  return 0;
}

/**
 * @brief Validate that a policy key is not set.
 *
 * @param key Policy key string.
 * @param failures Failure counter to increment on mismatch.
 * @return 0 when key is missing, 1 when it exists.
 */
static int lua_tso_ut_expect_missing(const char *key, int *failures)
{
  const char *value = NULL;

  value = luaz_policy_get_raw(key);
  if (value != NULL) {
    printf("LUZ00041 LUACFG UT unexpected key=%s value=%s\n", key, value);
    if (failures != NULL)
      (*failures)++;
    return 1;
  }
  return 0;
}

/**
 * @brief Execute LUACFG unit test assertions.
 *
 * @return 0 on success, 8 on failure.
 */
int main(void)
{
  int rc = 0;
  int failures = 0;

  /* Change note: add LUACFG unit test to validate policy parsing.
   * Problem: LUACFG behavior lacked a focused regression test.
   * Expected effect: UT_LUACFG fails fast on parser/config regressions.
   * Impact: policy loading is validated before integration tests run.
   */
  rc = luaz_policy_load("DD:LUACFG");
  if (rc != 0) {
    printf("LUZ00041 LUACFG UT failed: load rc=%d\n", rc);
    return 8;
  }
  if (!luaz_policy_loaded()) {
    printf("LUZ00041 LUACFG UT failed: policy not loaded\n");
    return 8;
  }

  lua_tso_ut_expect_value("allow.tso.cmd", "whitelist", &failures);
  lua_tso_ut_expect_value("tso.cmd.whitelist", "LISTCAT", &failures);
  lua_tso_ut_expect_value("tso.cmd.capture.default", "true", &failures);
  lua_tso_ut_expect_value("limits.output.lines", "25", &failures);
  lua_tso_ut_expect_value("tso.rexx.dd", "SYSEXEC", &failures);
  lua_tso_ut_expect_value("tso.rexx.exec", "LUTSO", &failures);
  lua_tso_ut_expect_value("luain.dd", "LUAIN", &failures);
  lua_tso_ut_expect_value("luaout.dd", "LUAOUT", &failures);
  lua_tso_ut_expect_value("luapath.dd", "LUAPATH", &failures);
  lua_tso_ut_expect_missing("unknown.key", &failures);

  if (failures != 0) {
    printf("LUZ00041 LUACFG UT failed: mismatches=%d\n", failures);
    return 8;
  }

  puts("LUZ00040 LUACFG UT OK");
  return 0;
}
