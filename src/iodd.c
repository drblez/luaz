/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO DDNAME I/O helpers for LUAPATH.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | luaz_io_dd_register | function | Register DDNAME-based LUAPATH hooks |
 */
#include "IODD"
#include "PLATFORM"

#include <stdio.h>
#include <string.h>

/**
 * @brief Read a full stream into a caller buffer or count required size.
 *
 * @param fp Open file stream to read.
 * @param buf Output buffer or NULL to only compute total length.
 * @param len In/out length: capacity on input, bytes read on output.
 * @return 0 on success, or -1 on failure (insufficient buffer or bad args).
 */
static int read_stream(FILE *fp, char *buf, unsigned long *len)
{
  unsigned long cap;
  unsigned long total = 0;
  size_t n;

  if (len == NULL)
    return -1;
  cap = *len;

  if (buf == NULL) {
    char tmp[512];
    while ((n = fread(tmp, 1, sizeof(tmp), fp)) > 0)
      total += (unsigned long)n;
    *len = total;
    return 0;
  }

  while (total < cap && (n = fread(buf + total, 1, cap - total, fp)) > 0)
    total += (unsigned long)n;
  if (total == cap) {
    int c = fgetc(fp);
    if (c != EOF) {
      ungetc(c, fp);
      return -1;
    }
  }
  *len = total;
  return 0;
}

/**
 * @brief Open a LUAPATH DDNAME member for reading.
 *
 * @param member Member name in the LUAPATH concatenation.
 * @param out Output FILE pointer on success.
 * @return 0 on success, or -1 on failure.
 */
static int luaz_dd_open(const char *member, FILE **out)
{
  char path[128];
  int rc;

  if (out == NULL || member == NULL)
    return -1;

  rc = snprintf(path, sizeof(path), "//DD:LUAPATH(%s)", member);
  if (rc <= 0 || (size_t)rc >= sizeof(path))
    return -1;

  *out = fopen(path, "r");
  return (*out == NULL) ? -1 : 0;
}

/**
 * @brief Read the LUAMAP member from LUAPATH into a buffer.
 *
 * @param buf Output buffer or NULL to only compute length.
 * @param len In/out length: capacity on input, bytes read on output.
 * @return 0 on success, or -1 on failure.
 */
static int luaz_luamap_read(char *buf, unsigned long *len)
{
  FILE *fp = NULL;
  int rc;

  if (luaz_dd_open("LUAMAP", &fp) != 0)
    return -1;

  rc = read_stream(fp, buf, len);
  fclose(fp);
  return rc;
}

/**
 * @brief Read a LUAPATH member into a buffer.
 *
 * @param member Member name to read.
 * @param buf Output buffer or NULL to only compute length.
 * @param len In/out length: capacity on input, bytes read on output.
 * @return 0 on success, or -1 on failure.
 */
static int luaz_member_read(const char *member, char *buf, unsigned long *len)
{
  FILE *fp = NULL;
  int rc;

  if (member == NULL)
    return -1;
  if (luaz_dd_open(member, &fp) != 0)
    return -1;

  rc = read_stream(fp, buf, len);
  fclose(fp);
  return rc;
}

/**
 * @brief Register DDNAME-based LUAPATH hooks with the platform layer.
 *
 * @return 0 on success, or nonzero on failure.
 */
int luaz_io_dd_register(void)
{
  struct luaz_platform_ops ops;
  memset(&ops, 0, sizeof(ops));
  ops.luapath_read_luamap = luaz_luamap_read;
  ops.luapath_read_member = luaz_member_read;
  return luaz_platform_set_ops(&ops);
}
