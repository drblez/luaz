/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO dataset API stubs.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | lua_ds_open_dd | function | Open DDNAME stream with mode |
 * | lua_ds_read | function | Read from DDNAME stream |
 * | lua_ds_write | function | Write to DDNAME stream |
 * | lua_ds_close | function | Close DDNAME stream |
 */
#include "DS"
#include "ERRORS"

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct lua_ds_handle {
  FILE *fp;
  char mode;
};

static int ddname_valid(const char *ddname)
{
  size_t n;
  if (ddname == NULL)
    return 0;
  n = strlen(ddname);
  if (n == 0 || n > 8)
    return 0;
  return 1;
}

int lua_ds_open_dd(const char *ddname, const char *mode, struct lua_ds_handle **out)
{
  char path[64];
  const char *fmode;
  const char *fmode_rec;
  const char *fmode_fb;
  struct lua_ds_handle *h;

  if (out)
    *out = 0;
  if (!ddname_valid(ddname) || out == NULL || mode == NULL || mode[0] == '\0')
    return LUZ_E_DS_OPEN;

  switch (mode[0]) {
  case 'r':
    fmode = "rb";
    fmode_rec = "rb,type=record";
    fmode_fb = "rb,recfm=FB,lrecl=80";
    break;
  case 'w':
    fmode = "wb";
    fmode_rec = "wb,type=record";
    fmode_fb = "wb,recfm=FB,lrecl=80";
    break;
  case 'a':
    fmode = "ab";
    fmode_rec = "ab,type=record";
    fmode_fb = "ab,recfm=FB,lrecl=80";
    break;
  default:
    return LUZ_E_DS_OPEN;
  }

  h = (struct lua_ds_handle *)malloc(sizeof(*h));
  if (h == NULL)
    return LUZ_E_DS_OPEN;

  h->fp = NULL;
  if (snprintf(path, sizeof(path), "//DD:%s", ddname) > 0)
    h->fp = fopen(path, fmode);
  if (h->fp == NULL && snprintf(path, sizeof(path), "DD:%s", ddname) > 0)
    h->fp = fopen(path, fmode);
  if (h->fp == NULL && snprintf(path, sizeof(path), "dd:%s", ddname) > 0)
    h->fp = fopen(path, fmode);
  if (h->fp == NULL && snprintf(path, sizeof(path), "%s", ddname) > 0)
    h->fp = fopen(path, fmode);
  if (h->fp == NULL && snprintf(path, sizeof(path), "//%s", ddname) > 0)
    h->fp = fopen(path, fmode);
  if (h->fp == NULL && snprintf(path, sizeof(path), "//DD:%s", ddname) > 0)
    h->fp = fopen(path, fmode_rec);
  if (h->fp == NULL && snprintf(path, sizeof(path), "DD:%s", ddname) > 0)
    h->fp = fopen(path, fmode_rec);
  if (h->fp == NULL && snprintf(path, sizeof(path), "dd:%s", ddname) > 0)
    h->fp = fopen(path, fmode_rec);
  if (h->fp == NULL && snprintf(path, sizeof(path), "%s", ddname) > 0)
    h->fp = fopen(path, fmode_rec);
  if (h->fp == NULL && snprintf(path, sizeof(path), "//%s", ddname) > 0)
    h->fp = fopen(path, fmode_rec);
  if (h->fp == NULL && snprintf(path, sizeof(path), "//DD:%s", ddname) > 0)
    h->fp = fopen(path, fmode_fb);
  if (h->fp == NULL && snprintf(path, sizeof(path), "DD:%s", ddname) > 0)
    h->fp = fopen(path, fmode_fb);
  if (h->fp == NULL && snprintf(path, sizeof(path), "dd:%s", ddname) > 0)
    h->fp = fopen(path, fmode_fb);
  if (h->fp == NULL && snprintf(path, sizeof(path), "%s", ddname) > 0)
    h->fp = fopen(path, fmode_fb);
  if (h->fp == NULL && snprintf(path, sizeof(path), "//%s", ddname) > 0)
    h->fp = fopen(path, fmode_fb);
  if (h->fp == NULL) {
    free(h);
    return LUZ_E_DS_OPEN;
  }
  h->mode = mode[0];
  *out = h;
  return 0;
}

int lua_ds_read(struct lua_ds_handle *h, void *buf, unsigned long *len)
{
  size_t n;
  if (h == NULL || h->fp == NULL || buf == NULL || len == NULL)
    return LUZ_E_DS_READ;
  if (h->mode != 'r')
    return LUZ_E_DS_READ;

  n = fread(buf, 1, (size_t)(*len), h->fp);
  *len = (unsigned long)n;
  return 0;
}

int lua_ds_write(struct lua_ds_handle *h, const void *buf, unsigned long len)
{
  size_t n;
  if (h == NULL || h->fp == NULL || buf == NULL)
    return LUZ_E_DS_WRITE;
  if (!(h->mode == 'w' || h->mode == 'a'))
    return LUZ_E_DS_WRITE;
  if (len == 0)
    return 0;
  n = fwrite(buf, 1, (size_t)len, h->fp);
  return (n == (size_t)len) ? 0 : LUZ_E_DS_WRITE;
}

int lua_ds_close(struct lua_ds_handle *h)
{
  if (h == NULL)
    return LUZ_E_DS_CLOSE;
  if (h->fp != NULL)
    fclose(h->fp);
  free(h);
  return 0;
}
