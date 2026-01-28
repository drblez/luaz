/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Lua/TSO dataset API (DDNAME/DSN I/O).
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | ddname_valid | function | Validate DDNAME length |
 * | ddname_copy_upper | function | Normalize DDNAME to upper-case |
 * | dsn_valid_plain | function | Validate DSN string for formatting |
 * | dsn_copy_upper | function | Normalize DSN to upper-case |
 * | dsn_build_path | function | Build MVS dataset path for fopen |
 * | member_valid | function | Validate PDS member name format |
 * | member_copy_upper | function | Normalize member name to upper-case |
 * | ds_member_build | function | Build DSN(member) string |
 * | qual_valid | function | Validate DSN qualifier format |
 * | qual_copy_upper | function | Normalize qualifier to upper-case |
 * | ds_tmpname_build | function | Build a temporary dataset name |
 * | ds_recfm_string | function | Build RECFM string from fldata flags |
 * | ds_dsorg_string | function | Build DSORG string from fldata flags |
 * | ds_mode_from_lua | function | Parse open mode from Lua args |
 * | ds_readline_stream | function | Read a line from a DDNAME stream |
 * | ds_ud_close | function | Close and free DS userdata handle |
 * | ds_ud_check | function | Validate DS userdata handle |
 * | l_ds_open_dd | function | Lua wrapper for ds.open_dd |
 * | l_ds_open_dsn | function | Lua wrapper for ds.open_dsn |
 * | l_ds_member | function | Lua helper for ds.member |
 * | l_ds_info | function | Lua helper for ds.info |
 * | l_ds_handle_readline | function | Lua handle:readline() |
 * | l_ds_handle_lines | function | Lua handle:lines() |
 * | l_ds_handle_writeline | function | Lua handle:writeline() |
 * | l_ds_handle_close | function | Lua handle:close() |
 * | l_ds_handle_gc | function | Lua handle:__gc() |
 * | l_ds_lines_iter | function | Iterator for handle:lines() |
 * | l_ds_remove | function | Lua wrapper for ds.remove |
 * | l_ds_rename | function | Lua wrapper for ds.rename |
 * | l_ds_tmpname | function | Lua wrapper for ds.tmpname |
 * | luaopen_ds | function | Lua module entrypoint |
 * | lua_ds_open_dd | function | Open DDNAME stream with mode |
 * | lua_ds_open_dsn | function | Open DSN stream with mode |
 * | lua_ds_read | function | Read from DDNAME stream |
 * | lua_ds_write | function | Write to DDNAME stream |
 * | lua_ds_close | function | Close DDNAME stream |
 */
#include "DS"
#include "ERRORS"

#include "LUA"
#include "LAUXLIB"

#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

extern int fldata(FILE *file, char *filename, fldata_t *info);

struct lua_ds_handle {
  FILE *fp;
  char mode;
};

struct lua_ds_ud {
  struct lua_ds_handle *h;
};

static const char *g_ds_handle_mt = "luaz.ds.handle";

/**
 * @brief Validate a DDNAME string for length only.
 *
 * @param ddname NUL-terminated DDNAME string.
 * @return 1 if length is 1..8, otherwise 0.
 */
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

/**
 * @brief Normalize DDNAME to uppercase in a fixed buffer.
 *
 * @param ddname Source DDNAME (may be mixed case).
 * @param out Output buffer for uppercase DDNAME.
 * @param cap Output buffer capacity in bytes.
 * @return 0 on success, or -1 on invalid arguments.
 */
static int ddname_copy_upper(const char *ddname, char *out, size_t cap)
{
  size_t i;
  if (out == NULL || cap == 0)
    return -1;
  out[0] = '\0';
  if (!ddname_valid(ddname))
    return -1;
  for (i = 0; i + 1 < cap && ddname[i] != '\0'; i++)
    out[i] = (char)toupper((unsigned char)ddname[i]);
  out[i] = '\0';
  return 0;
}

/**
 * @brief Validate a plain DSN string for basic formatting.
 *
 * @param dsn NUL-terminated DSN string (no // prefix or quotes).
 * @return 1 if the string looks valid, otherwise 0.
 */
static int dsn_valid_plain(const char *dsn)
{
  size_t i;
  size_t n;
  if (dsn == NULL)
    return 0;
  n = strlen(dsn);
  if (n == 0 || n > 60)
    return 0;
  /* Change note: enforce dataset-only names (no USS-like paths).
   * Problem: ds.open_dsn/remove/rename must not accept USS paths.
   * Expected effect: only valid MVS dataset characters are allowed.
   * Impact: inputs with '/' or whitespace are rejected early.
   */
  for (i = 0; i < n; i++) {
    unsigned char c = (unsigned char)dsn[i];
    if (c == '\'' || c == '/' || c == ' ' || c == '\t' || c == '\r' ||
        c == '\n')
      return 0;
    if (!(isalnum(c) || c == '.' || c == '-' || c == '$' || c == '#' ||
          c == '@' || c == '(' || c == ')'))
      return 0;
  }
  return 1;
}

/**
 * @brief Normalize a DSN string to uppercase in a fixed buffer.
 *
 * @param dsn Source DSN (plain form, without // prefix or quotes).
 * @param out Output buffer for uppercase DSN.
 * @param cap Output buffer capacity in bytes.
 * @return 0 on success, or -1 on invalid arguments.
 */
static int dsn_copy_upper(const char *dsn, char *out, size_t cap)
{
  size_t i;
  if (out == NULL || cap == 0)
    return -1;
  out[0] = '\0';
  if (!dsn_valid_plain(dsn))
    return -1;
  for (i = 0; i + 1 < cap && dsn[i] != '\0'; i++)
    out[i] = (char)toupper((unsigned char)dsn[i]);
  out[i] = '\0';
  return 0;
}

/**
 * @brief Build a z/OS MVS dataset path for fopen().
 *
 * @param dsn Input DSN (plain or already formatted).
 * @param out Output buffer for formatted path.
 * @param cap Output buffer capacity in bytes.
 * @return 0 on success, or -1 on invalid input.
 */
static int dsn_build_path(const char *dsn, char *out, size_t cap)
{
  char dsn_uc[64];
  size_t len;

  if (out == NULL || cap == 0)
    return -1;
  out[0] = '\0';
  if (dsn == NULL)
    return -1;

  len = strlen(dsn);
  if (len == 0 || len + 4 >= cap)
    return -1;

  /* Change note: format DSN with //'<dsn>' for fopen() as per IBM docs.
   * Problem: plain DSN strings are not recognized as MVS dataset paths.
   * Expected effect: ds.open_dsn opens fully-qualified datasets reliably.
   * Impact: ds.open_dsn accepts plain DSN strings without manual quoting.
   * Reference: src/ds.c.md (MVS dataset name format for fopen).
   */
  if (len >= 2 && dsn[0] == '/' && dsn[1] == '/') {
    if (len < 4 || dsn[2] != '\'')
      return -1;
    if (len >= cap)
      return -1;
    strncpy(out, dsn, cap - 1);
    out[cap - 1] = '\0';
    return 0;
  }
  if (strchr(dsn, '\'') != NULL) {
    if (snprintf(out, cap, "//%s", dsn) < 0)
      return -1;
    return 0;
  }
  if (dsn_copy_upper(dsn, dsn_uc, sizeof(dsn_uc)) != 0)
    return -1;
  if (snprintf(out, cap, "//'%s'", dsn_uc) < 0)
    return -1;
  return 0;
}

/**
 * @brief Validate a PDS/PDSE member name conservatively.
 *
 * @param member NUL-terminated member name.
 * @return 1 if the string looks valid, otherwise 0.
 */
static int member_valid(const char *member)
{
  size_t i;
  size_t n;
  if (member == NULL)
    return 0;
  n = strlen(member);
  if (n == 0 || n > 8)
    return 0;
  for (i = 0; i < n; i++) {
    unsigned char c = (unsigned char)member[i];
    if (!(isalnum(c) || c == '$' || c == '#' || c == '@'))
      return 0;
  }
  return 1;
}

/**
 * @brief Normalize a member name to uppercase in a fixed buffer.
 *
 * @param member Source member name.
 * @param out Output buffer for uppercase name.
 * @param cap Output buffer capacity in bytes.
 * @return 0 on success, or -1 on invalid arguments.
 */
static int member_copy_upper(const char *member, char *out, size_t cap)
{
  size_t i;
  if (out == NULL || cap == 0)
    return -1;
  out[0] = '\0';
  if (!member_valid(member))
    return -1;
  for (i = 0; i + 1 < cap && member[i] != '\0'; i++)
    out[i] = (char)toupper((unsigned char)member[i]);
  out[i] = '\0';
  return 0;
}

/**
 * @brief Build a DSN(member) string from a plain DSN and member name.
 *
 * @param dsn Plain DSN string.
 * @param member Member name string.
 * @param out Output buffer for DSN(member).
 * @param cap Output buffer capacity in bytes.
 * @return 0 on success, or -1 on invalid input.
 */
static int ds_member_build(const char *dsn, const char *member, char *out,
                           size_t cap)
{
  char dsn_uc[64];
  char mem_uc[9];

  if (out == NULL || cap == 0)
    return -1;
  out[0] = '\0';
  if (dsn == NULL || member == NULL)
    return -1;
  if (strchr(dsn, '(') != NULL || strchr(dsn, ')') != NULL)
    return -1;
  if (dsn_copy_upper(dsn, dsn_uc, sizeof(dsn_uc)) != 0)
    return -1;
  if (member_copy_upper(member, mem_uc, sizeof(mem_uc)) != 0)
    return -1;
  if (snprintf(out, cap, "%s(%s)", dsn_uc, mem_uc) < 0)
    return -1;
  return 0;
}

/**
 * @brief Validate a DSN qualifier for length and character set.
 *
 * @param qual NUL-terminated qualifier string.
 * @return 1 if valid, otherwise 0.
 */
static int qual_valid(const char *qual)
{
  size_t i;
  size_t n;
  if (qual == NULL)
    return 0;
  n = strlen(qual);
  if (n == 0 || n > 8)
    return 0;
  for (i = 0; i < n; i++) {
    unsigned char c = (unsigned char)qual[i];
    if (!(isalnum(c) || c == '$' || c == '#' || c == '@'))
      return 0;
  }
  return 1;
}

/**
 * @brief Normalize a qualifier to uppercase in a fixed buffer.
 *
 * @param qual Source qualifier string.
 * @param out Output buffer for uppercase qualifier.
 * @param cap Output buffer capacity in bytes.
 * @return 0 on success, or -1 on invalid arguments.
 */
static int qual_copy_upper(const char *qual, char *out, size_t cap)
{
  size_t i;
  if (out == NULL || cap == 0)
    return -1;
  out[0] = '\0';
  if (!qual_valid(qual))
    return -1;
  for (i = 0; i + 1 < cap && qual[i] != '\0'; i++)
    out[i] = (char)toupper((unsigned char)qual[i]);
  out[i] = '\0';
  return 0;
}

/**
 * @brief Build a temporary DSN using SYSUID and a time-based suffix.
 *
 * @param out Output buffer for DSN string.
 * @param cap Output buffer capacity in bytes.
 * @return 0 on success, or -1 on failure.
 */
static int ds_tmpname_build(char *out, size_t cap)
{
  static unsigned long counter = 0;
  const char *uid_env;
  char uid[9];
  unsigned long stamp;

  if (out == NULL || cap == 0)
    return -1;
  out[0] = '\0';

  uid_env = getenv("SYSUID");
  if (uid_env == NULL || qual_copy_upper(uid_env, uid, sizeof(uid)) != 0) {
    uid_env = getenv("LOGNAME");
    if (uid_env == NULL || qual_copy_upper(uid_env, uid, sizeof(uid)) != 0) {
      uid_env = getenv("USER");
      if (uid_env == NULL || qual_copy_upper(uid_env, uid, sizeof(uid)) != 0)
        strcpy(uid, "LUAZ");
    }
  }

  stamp = (unsigned long)time(NULL);
  stamp ^= counter++;
  stamp &= 0x0FFFFFFFUL;

  /* Change note: provide ds.tmpname without USS paths or TSO services.
   * Problem: tmpnam() may return USS paths and is disallowed.
   * Expected effect: ds.tmpname returns a valid MVS dataset name.
   * Impact: name is not allocated; caller must allocate if needed.
   */
  if (snprintf(out, cap, "%s.LUAZ.TMP.T%07lX", uid, stamp) < 0)
    return -1;
  return 0;
}

/**
 * @brief Build a RECFM string from fldata() flags.
 *
 * @param info fldata_t pointer.
 * @param out Output buffer for RECFM string.
 * @param cap Output buffer capacity in bytes.
 */
static void ds_recfm_string(const fldata_t *info, char *out, size_t cap)
{
  size_t pos = 0;
  if (out == NULL || cap == 0) {
    return;
  }
  out[0] = '\0';
  if (info == NULL)
    return;

  if (info->__recfmF && pos + 1 < cap)
    out[pos++] = 'F';
  if (info->__recfmV && pos + 1 < cap)
    out[pos++] = 'V';
  if (info->__recfmU && pos + 1 < cap)
    out[pos++] = 'U';
  if (info->__recfmBlk && pos + 1 < cap)
    out[pos++] = 'B';
  if (info->__recfmS && pos + 1 < cap)
    out[pos++] = 'S';
  if (info->__recfmASA && pos + 1 < cap)
    out[pos++] = 'A';
  if (info->__recfmM && pos + 1 < cap)
    out[pos++] = 'M';
  out[pos] = '\0';
}

/**
 * @brief Build a DSORG string from fldata() flags.
 *
 * @param info fldata_t pointer.
 * @param out Output buffer for DSORG string.
 * @param cap Output buffer capacity in bytes.
 */
static void ds_dsorg_string(const fldata_t *info, char *out, size_t cap)
{
  const char *value = "";

  if (out == NULL || cap == 0) {
    return;
  }
  out[0] = '\0';
  if (info == NULL)
    return;

  if (info->__dsorgPDSE)
    value = "PDSE";
  else if (info->__dsorgPO)
    value = "PO";
  else if (info->__dsorgPS)
    value = "PS";
  else if (info->__dsorgVSAM)
    value = "VSAM";
  else if (info->__dsorgHFS)
    value = "HFS";
  else if (info->__dsorgHiper)
    value = "HIPER";
  else if (info->__dsorgTemp)
    value = "TEMP";

  strncpy(out, value, cap - 1);
  out[cap - 1] = '\0';
}

/**
 * @brief Parse the open mode from Lua args (string or table {mode=...}).
 *
 * @param L Lua state.
 * @param idx Lua stack index for the mode argument.
 * @param out_mode Output buffer for mode char + NUL (size >= 2).
 * @return 0 on success, or -1 on invalid argument.
 */
static int ds_mode_from_lua(lua_State *L, int idx, char *out_mode)
{
  const char *mode = NULL;
  if (out_mode == NULL)
    return -1;
  out_mode[0] = 'r';
  out_mode[1] = '\0';
  if (lua_isnoneornil(L, idx))
    return 0;
  if (lua_isstring(L, idx)) {
    mode = lua_tostring(L, idx);
  } else if (lua_istable(L, idx)) {
    lua_getfield(L, idx, "mode");
    if (lua_isstring(L, -1))
      mode = lua_tostring(L, -1);
    lua_pop(L, 1);
  } else {
    return -1;
  }
  if (mode == NULL || mode[0] == '\0')
    return 0;
  if (mode[0] != 'r' && mode[0] != 'w' && mode[0] != 'a')
    return -1;
  out_mode[0] = mode[0];
  return 0;
}

/**
 * @brief Read a logical line from a dataset stream.
 *
 * @param L Lua state for buffer allocation.
 * @param fp Open FILE stream.
 * @return 1 and push line on success, 0 on EOF, -1 on error.
 */
static int ds_readline_stream(lua_State *L, FILE *fp)
{
  char buf[256];
  luaL_Buffer b;
  int have_data = 0;

  if (L == NULL || fp == NULL)
    return -1;

  luaL_buffinit(L, &b);
  while (fgets(buf, sizeof(buf), fp) != NULL) {
    size_t len = strlen(buf);
    have_data = 1;
    if (len > 0 && buf[len - 1] == '\n') {
      luaL_addlstring(&b, buf, len - 1);
      luaL_pushresult(&b);
      return 1;
    }
    luaL_addlstring(&b, buf, len);
    if (len + 1 < sizeof(buf)) {
      luaL_pushresult(&b);
      return 1;
    }
  }

  if (ferror(fp))
    return -1;
  if (!have_data)
    return 0;
  luaL_pushresult(&b);
  return 1;
}

/**
 * @brief Close a DS userdata handle and clear its pointer.
 *
 * @param ud DS userdata wrapper.
 * @return 0 on success, or LUZ_E_DS_CLOSE on failure.
 */
static int ds_ud_close(struct lua_ds_ud *ud)
{
  if (ud == NULL || ud->h == NULL)
    return LUZ_E_DS_CLOSE;
  if (lua_ds_close(ud->h) != 0)
    return LUZ_E_DS_CLOSE;
  ud->h = NULL;
  return 0;
}

/**
 * @brief Validate and return the DS handle from Lua userdata.
 *
 * @param L Lua state.
 * @param idx Stack index.
 * @return DS handle pointer or NULL if invalid/closed.
 */
static struct lua_ds_handle *ds_ud_check(lua_State *L, int idx)
{
  struct lua_ds_ud *ud = NULL;
  if (L == NULL)
    return NULL;
  ud = (struct lua_ds_ud *)luaL_checkudata(L, idx, g_ds_handle_mt);
  if (ud == NULL || ud->h == NULL)
    return NULL;
  return ud->h;
}

/**
 * @brief Open a DDNAME stream with the given mode.
 *
 * @param ddname DDNAME string.
 * @param mode Mode string ("r", "w", or "a").
 * @param out Output handle pointer.
 * @return 0 on success, or LUZ_E_DS_OPEN on failure.
 */
int lua_ds_open_dd(const char *ddname, const char *mode, struct lua_ds_handle **out)
{
  char path[64];
  const char *fmode;
  const char *fmode_rec;
  const char *fmode_fb;
  struct lua_ds_handle *h;
  char ddname_uc[9];

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

  /* Change note: normalize DDNAME to upper-case before fopen.
   * Problem: mixed-case DDNAMEs can fail to resolve in DD: paths.
   * Expected effect: DDNAME lookup is consistent for batch DDs.
   * Impact: ds.open_dd accepts lower-case DDNAMEs.
   */
  if (ddname_copy_upper(ddname, ddname_uc, sizeof(ddname_uc)) != 0) {
    free(h);
    return LUZ_E_DS_OPEN;
  }

  h->fp = NULL;
  if (snprintf(path, sizeof(path), "//DD:%s", ddname_uc) > 0)
    h->fp = fopen(path, fmode);
  if (h->fp == NULL && snprintf(path, sizeof(path), "DD:%s", ddname_uc) > 0)
    h->fp = fopen(path, fmode);
  if (h->fp == NULL && snprintf(path, sizeof(path), "dd:%s", ddname_uc) > 0)
    h->fp = fopen(path, fmode);
  if (h->fp == NULL && snprintf(path, sizeof(path), "%s", ddname_uc) > 0)
    h->fp = fopen(path, fmode);
  if (h->fp == NULL && snprintf(path, sizeof(path), "//%s", ddname_uc) > 0)
    h->fp = fopen(path, fmode);
  if (h->fp == NULL && snprintf(path, sizeof(path), "//DD:%s", ddname_uc) > 0)
    h->fp = fopen(path, fmode_rec);
  if (h->fp == NULL && snprintf(path, sizeof(path), "DD:%s", ddname_uc) > 0)
    h->fp = fopen(path, fmode_rec);
  if (h->fp == NULL && snprintf(path, sizeof(path), "dd:%s", ddname_uc) > 0)
    h->fp = fopen(path, fmode_rec);
  if (h->fp == NULL && snprintf(path, sizeof(path), "%s", ddname_uc) > 0)
    h->fp = fopen(path, fmode_rec);
  if (h->fp == NULL && snprintf(path, sizeof(path), "//%s", ddname_uc) > 0)
    h->fp = fopen(path, fmode_rec);
  if (h->fp == NULL && snprintf(path, sizeof(path), "//DD:%s", ddname_uc) > 0)
    h->fp = fopen(path, fmode_fb);
  if (h->fp == NULL && snprintf(path, sizeof(path), "DD:%s", ddname_uc) > 0)
    h->fp = fopen(path, fmode_fb);
  if (h->fp == NULL && snprintf(path, sizeof(path), "dd:%s", ddname_uc) > 0)
    h->fp = fopen(path, fmode_fb);
  if (h->fp == NULL && snprintf(path, sizeof(path), "%s", ddname_uc) > 0)
    h->fp = fopen(path, fmode_fb);
  if (h->fp == NULL && snprintf(path, sizeof(path), "//%s", ddname_uc) > 0)
    h->fp = fopen(path, fmode_fb);
  if (h->fp == NULL) {
    free(h);
    return LUZ_E_DS_OPEN;
  }
  h->mode = mode[0];
  *out = h;
  return 0;
}

/**
 * @brief Open a DSN stream with the given mode.
 *
 * @param dsn Dataset name string (plain or fully formatted).
 * @param mode Mode string ("r", "w", or "a").
 * @param out Output handle pointer.
 * @return 0 on success, or LUZ_E_DS_OPEN on failure.
 */
int lua_ds_open_dsn(const char *dsn, const char *mode, struct lua_ds_handle **out)
{
  char path[96];
  const char *fmode;
  const char *fmode_rec;
  const char *fmode_fb;
  struct lua_ds_handle *h;

  if (out)
    *out = 0;
  if (dsn == NULL || out == NULL || mode == NULL || mode[0] == '\0')
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

  if (dsn_build_path(dsn, path, sizeof(path)) != 0) {
    free(h);
    return LUZ_E_DS_OPEN;
  }

  h->fp = fopen(path, fmode);
  if (h->fp == NULL)
    h->fp = fopen(path, fmode_rec);
  if (h->fp == NULL)
    h->fp = fopen(path, fmode_fb);
  if (h->fp == NULL) {
    free(h);
    return LUZ_E_DS_OPEN;
  }
  h->mode = mode[0];
  *out = h;
  return 0;
}

/**
 * @brief Read bytes from a DDNAME stream.
 *
 * @param h DS handle.
 * @param buf Output buffer.
 * @param len In/out: capacity on input, bytes read on output.
 * @return 0 on success, or LUZ_E_DS_READ on failure.
 */
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

/**
 * @brief Write bytes to a DDNAME stream.
 *
 * @param h DS handle.
 * @param buf Input buffer.
 * @param len Number of bytes to write.
 * @return 0 on success, or LUZ_E_DS_WRITE on failure.
 */
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

/**
 * @brief Close a DDNAME stream and free the handle.
 *
 * @param h DS handle.
 * @return 0 on success, or LUZ_E_DS_CLOSE on failure.
 */
int lua_ds_close(struct lua_ds_handle *h)
{
  if (h == NULL)
    return LUZ_E_DS_CLOSE;
  if (h->fp != NULL)
    fclose(h->fp);
  free(h);
  return 0;
}

/**
 * @brief Lua binding for ds.open_dd.
 *
 * @param L Lua state.
 * @return 1 on success (handle), or 3 on failure (nil, message, code).
 */
static int l_ds_open_dd(lua_State *L)
{
  const char *ddname = luaL_checkstring(L, 1);
  char mode[2];
  struct lua_ds_handle *h = NULL;
  struct lua_ds_ud *ud = NULL;
  int rc;

  /* Change note: add Lua bindings for DDNAME I/O.
   * Problem: ds.open_dd was only available via C API or Lua stub.
   * Expected effect: Lua scripts can open DDNAME datasets directly.
   * Impact: os.remove/rename/tmpname now resolve to ds module stubs.
   */
  if (ds_mode_from_lua(L, 2, mode) != 0) {
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30006 ds.open_dd invalid mode");
    lua_pushinteger(L, LUZ_E_DS_OPEN);
    return 3;
  }

  rc = lua_ds_open_dd(ddname, mode, &h);
  if (rc != 0 || h == NULL) {
    lua_pushnil(L);
    lua_pushfstring(L,
                    "LUZ30006 ds.open_dd failed dd=%s errno=%d errno2=%d",
                    ddname, errno, __errno2());
    lua_pushinteger(L, LUZ_E_DS_OPEN);
    return 3;
  }

  ud = (struct lua_ds_ud *)lua_newuserdatauv(L, sizeof(*ud), 0);
  ud->h = h;
  luaL_setmetatable(L, g_ds_handle_mt);
  return 1;
}

/**
 * @brief Lua binding for ds.open_dsn.
 *
 * @param L Lua state.
 * @return 1 on success (handle), or 3 on failure (nil, message, code).
 */
static int l_ds_open_dsn(lua_State *L)
{
  const char *dsn = luaL_checkstring(L, 1);
  char mode[2];
  struct lua_ds_handle *h = NULL;
  struct lua_ds_ud *ud = NULL;
  int rc;

  /* Change note: add Lua binding for DSN-based dataset open.
   * Problem: Lua scripts could only access datasets via DDNAME.
   * Expected effect: scripts can open fully-qualified DSNs directly.
   * Impact: ds.open_dsn enables DSN I/O without prior DD allocation.
   */
  if (ds_mode_from_lua(L, 2, mode) != 0) {
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30006 ds.open_dsn invalid mode");
    lua_pushinteger(L, LUZ_E_DS_OPEN);
    return 3;
  }

  rc = lua_ds_open_dsn(dsn, mode, &h);
  if (rc != 0 || h == NULL) {
    lua_pushnil(L);
    lua_pushfstring(L,
                    "LUZ30006 ds.open_dsn failed dsn=%s errno=%d errno2=%d",
                    dsn, errno, __errno2());
    lua_pushinteger(L, LUZ_E_DS_OPEN);
    return 3;
  }

  ud = (struct lua_ds_ud *)lua_newuserdatauv(L, sizeof(*ud), 0);
  ud->h = h;
  luaL_setmetatable(L, g_ds_handle_mt);
  return 1;
}

/**
 * @brief Lua helper for ds.member(dsn, member).
 *
 * @param L Lua state.
 * @return 1 on success (string), or 3 on failure (nil, message, code).
 */
static int l_ds_member(lua_State *L)
{
  const char *dsn = luaL_checkstring(L, 1);
  const char *member = luaL_checkstring(L, 2);
  char buf[80];

  /* Change note: add ds.member helper for building DSN(member) strings.
   * Problem: callers had to manually format member names for ds.open_dsn.
   * Expected effect: consistent member formatting and validation in one place.
   * Impact: ds.member returns a plain DSN(member) string for ds.open_dsn.
   */
  if (ds_member_build(dsn, member, buf, sizeof(buf)) != 0) {
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30029 ds.member invalid input");
    lua_pushinteger(L, LUZ_E_DS_MEMBER);
    return 3;
  }

  lua_pushstring(L, buf);
  return 1;
}

/**
 * @brief Lua helper for ds.info(dsn).
 *
 * @param L Lua state.
 * @return 1 on success (table), or 3 on failure (nil, message, code).
 */
static int l_ds_info(lua_State *L)
{
  const char *dsn = luaL_checkstring(L, 1);
  char path[96];
  char filename[64];
  char recfm[8];
  char dsorg[8];
  fldata_t info;
  FILE *fp;
  int rc;

  /* Change note: implement ds.info via fldata() on MVS datasets.
   * Problem: ds.info was missing and dataset attributes were unavailable.
   * Expected effect: Lua can inspect RECFM/DSORG/LRECL/BLKSIZE via C runtime.
   * Impact: ds.info opens the dataset read-only and returns metadata table.
   * Reference: src/ds.c.md (fldata() structure and recfm=* guidance).
   */
  if (dsn_build_path(dsn, path, sizeof(path)) != 0) {
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30037 ds.info invalid input");
    lua_pushinteger(L, LUZ_E_DS_INFO);
    return 3;
  }

  fp = fopen(path, "rb,recfm=*");
  if (fp == NULL)
    fp = fopen(path, "rb,type=record");
  if (fp == NULL)
    fp = fopen(path, "rb");
  if (fp == NULL) {
    lua_pushnil(L);
    lua_pushfstring(L, "LUZ30037 ds.info open failed dsn=%s errno=%d errno2=%d",
                    dsn, errno, __errno2());
    lua_pushinteger(L, LUZ_E_DS_INFO);
    return 3;
  }

  memset(&info, 0, sizeof(info));
  filename[0] = '\0';
  rc = fldata(fp, filename, &info);
  fclose(fp);
  if (rc != 0) {
    lua_pushnil(L);
    lua_pushfstring(L,
                    "LUZ30037 ds.info fldata failed dsn=%s errno=%d errno2=%d",
                    dsn, errno, __errno2());
    lua_pushinteger(L, LUZ_E_DS_INFO);
    return 3;
  }

  ds_recfm_string(&info, recfm, sizeof(recfm));
  ds_dsorg_string(&info, dsorg, sizeof(dsorg));

  lua_newtable(L);
  if (info.__dsname != NULL && info.__dsname[0] != '\0') {
    lua_pushstring(L, info.__dsname);
    lua_setfield(L, -2, "dsname");
  }
  if (filename[0] != '\0') {
    lua_pushstring(L, filename);
    lua_setfield(L, -2, "filename");
  }
  lua_pushstring(L, recfm);
  lua_setfield(L, -2, "recfm");
  lua_pushstring(L, dsorg);
  lua_setfield(L, -2, "dsorg");
  lua_pushinteger(L, (lua_Integer)info.__maxreclen);
  lua_setfield(L, -2, "lrecl");
  lua_pushinteger(L, (lua_Integer)info.__blksize);
  lua_setfield(L, -2, "blksize");

  lua_newtable(L);
  lua_pushboolean(L, info.__recfmF);
  lua_setfield(L, -2, "F");
  lua_pushboolean(L, info.__recfmV);
  lua_setfield(L, -2, "V");
  lua_pushboolean(L, info.__recfmU);
  lua_setfield(L, -2, "U");
  lua_pushboolean(L, info.__recfmBlk);
  lua_setfield(L, -2, "B");
  lua_pushboolean(L, info.__recfmS);
  lua_setfield(L, -2, "S");
  lua_pushboolean(L, info.__recfmASA);
  lua_setfield(L, -2, "A");
  lua_pushboolean(L, info.__recfmM);
  lua_setfield(L, -2, "M");
  lua_setfield(L, -2, "recfm_flags");

  lua_newtable(L);
  lua_pushboolean(L, info.__dsorgPS);
  lua_setfield(L, -2, "PS");
  lua_pushboolean(L, info.__dsorgPO);
  lua_setfield(L, -2, "PO");
  lua_pushboolean(L, info.__dsorgPDSE);
  lua_setfield(L, -2, "PDSE");
  lua_pushboolean(L, info.__dsorgPDSmem);
  lua_setfield(L, -2, "PDSMEM");
  lua_pushboolean(L, info.__dsorgPDSdir);
  lua_setfield(L, -2, "PDSDIR");
  lua_pushboolean(L, info.__dsorgConcat);
  lua_setfield(L, -2, "CONCAT");
  lua_pushboolean(L, info.__dsorgMem);
  lua_setfield(L, -2, "MEM");
  lua_pushboolean(L, info.__dsorgHiper);
  lua_setfield(L, -2, "HIPER");
  lua_pushboolean(L, info.__dsorgTemp);
  lua_setfield(L, -2, "TEMP");
  lua_pushboolean(L, info.__dsorgVSAM);
  lua_setfield(L, -2, "VSAM");
  lua_pushboolean(L, info.__dsorgHFS);
  lua_setfield(L, -2, "HFS");
  lua_setfield(L, -2, "dsorg_flags");

  return 1;
}

/**
 * @brief Lua method: handle:readline().
 *
 * @param L Lua state.
 * @return 1 value (line) or 0 on EOF; returns 3 on error.
 */
static int l_ds_handle_readline(lua_State *L)
{
  struct lua_ds_handle *h = ds_ud_check(L, 1);
  int rc;
  if (h == NULL || h->mode != 'r') {
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30007 ds.read invalid handle");
    lua_pushinteger(L, LUZ_E_DS_READ);
    return 3;
  }

  rc = ds_readline_stream(L, h->fp);
  if (rc < 0) {
    lua_pushnil(L);
    lua_pushfstring(L, "LUZ30007 ds.read failed errno=%d errno2=%d",
                    errno, __errno2());
    lua_pushinteger(L, LUZ_E_DS_READ);
    return 3;
  }
  return (rc == 0) ? 0 : 1;
}

/**
 * @brief Lua iterator for handle:lines().
 *
 * @param L Lua state.
 * @return 1 value (line) or 0 on EOF; raises on error.
 */
static int l_ds_lines_iter(lua_State *L)
{
  struct lua_ds_ud *ud =
      (struct lua_ds_ud *)lua_touserdata(L, lua_upvalueindex(1));
  struct lua_ds_handle *h = (ud != NULL) ? ud->h : NULL;
  int rc;

  if (h == NULL || h->mode != 'r')
    return luaL_error(L, "LUZ30007 ds.read invalid handle");

  rc = ds_readline_stream(L, h->fp);
  if (rc < 0)
    return luaL_error(L, "LUZ30007 ds.read failed");
  return (rc == 0) ? 0 : 1;
}

/**
 * @brief Lua method: handle:lines().
 *
 * @param L Lua state.
 * @return 1 value (iterator function).
 */
static int l_ds_handle_lines(lua_State *L)
{
  luaL_checkudata(L, 1, g_ds_handle_mt);
  lua_pushvalue(L, 1);
  lua_pushcclosure(L, l_ds_lines_iter, 1);
  return 1;
}

/**
 * @brief Lua method: handle:writeline(line).
 *
 * @param L Lua state.
 * @return 1 on success, or 3 on failure.
 */
static int l_ds_handle_writeline(lua_State *L)
{
  struct lua_ds_handle *h = ds_ud_check(L, 1);
  size_t len = 0;
  const char *line = luaL_checklstring(L, 2, &len);
  int rc;

  if (h == NULL || (h->mode != 'w' && h->mode != 'a')) {
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30008 ds.write invalid handle");
    lua_pushinteger(L, LUZ_E_DS_WRITE);
    return 3;
  }

  /* Change note: writeline appends a newline if missing.
   * Problem: datasets written line-by-line need a consistent delimiter.
   * Expected effect: writeline behaves like file:write(line .. "\\n").
   * Impact: callers get one record per writeline by default.
   */
  rc = lua_ds_write(h, line, (unsigned long)len);
  if (rc == 0 && (len == 0 || line[len - 1] != '\n'))
    rc = lua_ds_write(h, "\n", 1);
  if (rc != 0) {
    lua_pushnil(L);
    lua_pushfstring(L, "LUZ30008 ds.write failed errno=%d errno2=%d",
                    errno, __errno2());
    lua_pushinteger(L, LUZ_E_DS_WRITE);
    return 3;
  }
  lua_pushboolean(L, 1);
  return 1;
}

/**
 * @brief Lua method: handle:close().
 *
 * @param L Lua state.
 * @return 1 on success, or 3 on failure.
 */
static int l_ds_handle_close(lua_State *L)
{
  struct lua_ds_ud *ud =
      (struct lua_ds_ud *)luaL_checkudata(L, 1, g_ds_handle_mt);
  int rc = ds_ud_close(ud);
  if (rc != 0) {
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30009 ds.close failed");
    lua_pushinteger(L, LUZ_E_DS_CLOSE);
    return 3;
  }
  lua_pushboolean(L, 1);
  return 1;
}

/**
 * @brief Lua method: __gc for DS handle.
 *
 * @param L Lua state.
 * @return 0 (ignored).
 */
static int l_ds_handle_gc(lua_State *L)
{
  struct lua_ds_ud *ud =
      (struct lua_ds_ud *)luaL_checkudata(L, 1, g_ds_handle_mt);
  ds_ud_close(ud);
  return 0;
}

/**
 * @brief Lua binding for ds.remove.
 *
 * @param L Lua state.
 * @return 1 on success, or 3 on failure (nil, message, code).
 */
static int l_ds_remove(lua_State *L)
{
  const char *dsn = luaL_checkstring(L, 1);
  char path[96];
  int rc;

  /* Change note: implement ds.remove via C runtime remove() on datasets.
   * Problem: ds.remove was a stub and could not delete datasets.
   * Expected effect: Lua can delete datasets without TSO/IDCAMS/REXX.
   * Impact: ds.remove uses //'<dsn>' paths built from input DSNs.
   */
  if (dsn_build_path(dsn, path, sizeof(path)) != 0) {
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30026 ds.remove invalid input");
    lua_pushinteger(L, LUZ_E_DS_REMOVE);
    return 3;
  }

  rc = remove(path);
  if (rc != 0) {
    lua_pushnil(L);
    lua_pushfstring(L,
                    "LUZ30026 ds.remove failed dsn=%s errno=%d errno2=%d",
                    dsn, errno, __errno2());
    lua_pushinteger(L, LUZ_E_DS_REMOVE);
    return 3;
  }

  lua_pushboolean(L, 1);
  return 1;
}

/**
 * @brief Lua binding for ds.rename.
 *
 * @param L Lua state.
 * @return 1 on success, or 3 on failure (nil, message, code).
 */
static int l_ds_rename(lua_State *L)
{
  const char *old_dsn = luaL_checkstring(L, 1);
  const char *new_dsn = luaL_checkstring(L, 2);
  char old_path[96];
  char new_path[96];
  int rc;

  /* Change note: implement ds.rename via C runtime rename() on datasets.
   * Problem: ds.rename was a stub and could not rename datasets.
   * Expected effect: Lua can rename datasets without TSO/IDCAMS/REXX.
   * Impact: ds.rename uses //'<dsn>' paths built from input DSNs.
   */
  if (dsn_build_path(old_dsn, old_path, sizeof(old_path)) != 0 ||
      dsn_build_path(new_dsn, new_path, sizeof(new_path)) != 0) {
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30027 ds.rename invalid input");
    lua_pushinteger(L, LUZ_E_DS_RENAME);
    return 3;
  }

  rc = rename(old_path, new_path);
  if (rc != 0) {
    lua_pushnil(L);
    lua_pushfstring(L,
                    "LUZ30027 ds.rename failed old=%s new=%s errno=%d "
                    "errno2=%d",
                    old_dsn, new_dsn, errno, __errno2());
    lua_pushinteger(L, LUZ_E_DS_RENAME);
    return 3;
  }

  lua_pushboolean(L, 1);
  return 1;
}

/**
 * @brief Lua binding for ds.tmpname.
 *
 * @param L Lua state.
 * @return 1 on success (string), or 3 on failure (nil, message, code).
 */
static int l_ds_tmpname(lua_State *L)
{
  char buf[64];

  /* Change note: implement ds.tmpname as an MVS dataset name.
   * Problem: ds.tmpname was a stub and os.tmpname is disabled on z/OS.
   * Expected effect: callers can obtain a dataset name without USS paths.
   * Impact: returned DSN is not allocated; caller must allocate it.
   */
  if (ds_tmpname_build(buf, sizeof(buf)) != 0) {
    lua_pushnil(L);
    lua_pushstring(L, "LUZ30028 ds.tmpname failed");
    lua_pushinteger(L, LUZ_E_DS_TMPNAME);
    return 3;
  }
  lua_pushstring(L, buf);
  return 1;
}

/**
 * @brief Lua module entrypoint for ds.
 *
 * @param L Lua state.
 * @return 1 (module table).
 */
int luaopen_ds(lua_State *L)
{
  luaL_Reg ds_funcs[] = {
      {"open_dd", l_ds_open_dd},
      {"open_dsn", l_ds_open_dsn},
      {"member", l_ds_member},
      {"info", l_ds_info},
      {"remove", l_ds_remove},
      {"rename", l_ds_rename},
      {"tmpname", l_ds_tmpname},
      {NULL, NULL},
  };
  luaL_Reg ds_handle_funcs[] = {
      {"readline", l_ds_handle_readline},
      {"lines", l_ds_handle_lines},
      {"writeline", l_ds_handle_writeline},
      {"close", l_ds_handle_close},
      {"__gc", l_ds_handle_gc},
      {NULL, NULL},
  };

  luaL_newmetatable(L, g_ds_handle_mt);
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");
  luaL_setfuncs(L, ds_handle_funcs, 0);
  lua_pop(L, 1);

  luaL_newlib(L, ds_funcs);
  return 1;
}
