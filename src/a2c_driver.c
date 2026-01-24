/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * A2CDRIVER - C main for ASM->C OS-linkage validation.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | lua_tso_a2c_driver_main | function | Call ASM A2CTEST entrypoint and return its RC |
 * | main | function | Required C runtime entrypoint delegating to lua_tso_a2c_driver_main |
 *
 * Platform Requirements:
 * - LE: required (C runtime initializes LE).
 * - AMODE: 31-bit.
 * - EBCDIC: inputs/outputs are EBCDIC in batch.
 * - DDNAME I/O: no direct I/O; ASM handles output.
 */

/**
 * @brief ASM test entrypoint invoked by the C driver.
 *
 * @return 0 on success or 8 on validation failure.
 */
#pragma map(a2c_test, "A2CTEST")
#pragma linkage(a2c_test, OS)
int a2c_test(void);

/**
 * @brief Call the ASM test entrypoint and return its RC.
 *
 * @return 0 on success or 8 on validation failure.
 */
int lua_tso_a2c_driver_main(void)
{
  return a2c_test();
}

/**
 * @brief Required C runtime entrypoint that delegates to the driver logic.
 *
 * @return Return code from lua_tso_a2c_driver_main.
 */
int main(void)
{
  return lua_tso_a2c_driver_main();
}
