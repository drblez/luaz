/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * Minimal IRXEXEC + LUTSO test (no Lua) to isolate batch failure.
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | main | function | Invoke LUTSO via IRXEXEC and report RC |
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#pragma linkage(fetch, OS)
extern void (*fetch(const char *name))();

typedef int (*irxexec_fn)();
typedef void (*ikjtsoev_fn)(int *, int *, int *, int *, void **);

typedef struct EXECBLK_type {
  char EXECBLK_ACRYN[8];
  int EXECBLK_LENGTH;
  int EXECBLK_reserved;
  char EXECBLK_MEMBER[8];
  char EXECBLK_DDNAME[8];
  char EXECBLK_SUBCOM[8];
  void *EXECBLK_DSNPTR;
  int EXECBLK_DSNLEN;
} EXECBLK_type;

typedef struct one_parameter_type {
  void *ARGSTRING_PTR;
  int ARGSTRING_LENGTH;
} one_parameter_type;

typedef struct EVALBLK_type {
  int EVALBLK_EVPAD1;
  int EVALBLK_EVSIZE;
  int EVALBLK_EVLEN;
  int EVALBLK_EVPAD2;
  char EVALBLK_EVDATA[256];
} EVALBLK_type;

typedef struct IRXEXEC_type {
  EXECBLK_type **execblk_ptr;
  one_parameter_type **argtable_ptr;
  int *flags_ptr;
  int *instblk_ptr;
  int *reserved_parm5;
  EVALBLK_type **evalblk_ptr;
  int *reserved_workarea_ptr;
  int *reserved_userfield_ptr;
  int *reserved_envblock_ptr;
  int *rexx_rc_ptr;
} IRXEXEC_type;

static int evalblk_to_rc(const EVALBLK_type *evalblk, int *out_rc)
{
  int i = 0;
  int rc = 0;
  int sign = 1;

  if (evalblk == NULL || out_rc == NULL)
    return 0;
  if (evalblk->EVALBLK_EVLEN <= 0 ||
      evalblk->EVALBLK_EVLEN > (int)sizeof(evalblk->EVALBLK_EVDATA))
    return 0;
  if (evalblk->EVALBLK_EVDATA[0] == (char)0x60) {
    sign = -1;
    i = 1;
  }
  for (; i < evalblk->EVALBLK_EVLEN; i++) {
    unsigned char c = (unsigned char)evalblk->EVALBLK_EVDATA[i];
    if (c < 0xF0 || c > 0xF9)
      break;
    rc = (rc * 10) + (c - 0xF0);
  }
  if ((sign == -1 && i == 1) || (sign == 1 && i == 0))
    return 0;
  *out_rc = rc * sign;
  return 1;
}

int main(void)
{
  irxexec_fn irxexec;
  ikjtsoev_fn ikjtsoev;
  IRXEXEC_type param;
  EXECBLK_type execblk;
  EXECBLK_type *execblk_ptr = &execblk;
  EVALBLK_type evalblk;
  EVALBLK_type *evalblk_ptr = &evalblk;
  one_parameter_type args[4];
  one_parameter_type *argtable_ptr = &args[0];
  int flags = 0;
  int rexx_rc = 0;
  int rc = 0;
  int eval_rc = 0;
  void *cppl = NULL;
  int tparm = 0;
  int trc = 0;
  int treason = 0;
  int tabend = 0;

  puts("LUZ00018 TSOX start");
  fflush(NULL);

  irxexec = (irxexec_fn)fetch("IRXEXEC");
  if (irxexec == NULL) {
    puts("LUZ00019 TSOX failed: fetch IRXEXEC");
    return 8;
  }
  ikjtsoev = (ikjtsoev_fn)fetch("IKJTSOEV");
  if (ikjtsoev != NULL) {
    ikjtsoev(&tparm, &trc, &treason, &tabend, &cppl);
  }

  memset(&execblk, 0, sizeof(execblk));
  memcpy(execblk.EXECBLK_ACRYN, "IRXEXECB", 8);
  execblk.EXECBLK_LENGTH = 48;
  memset(execblk.EXECBLK_MEMBER, ' ', sizeof(execblk.EXECBLK_MEMBER));
  memset(execblk.EXECBLK_DDNAME, ' ', sizeof(execblk.EXECBLK_DDNAME));
  memset(execblk.EXECBLK_SUBCOM, ' ', sizeof(execblk.EXECBLK_SUBCOM));
  memcpy(execblk.EXECBLK_MEMBER, "LUTSO", 5);
  memcpy(execblk.EXECBLK_DDNAME, "SYSEXEC", 7);
  memcpy(execblk.EXECBLK_SUBCOM, "TSO", 3);

  memset(&evalblk, 0, sizeof(evalblk));
  evalblk.EVALBLK_EVSIZE = 34;

  args[0].ARGSTRING_PTR = (void *)"CMD";
  args[0].ARGSTRING_LENGTH = 3;
  args[1].ARGSTRING_PTR = (void *)"TIME";
  args[1].ARGSTRING_LENGTH = 4;
  args[2].ARGSTRING_PTR = (void *)"TSOOUT";
  args[2].ARGSTRING_LENGTH = 6;
  args[3].ARGSTRING_PTR = (void *)0xFFFFFFFFu;
  args[3].ARGSTRING_LENGTH = (int)0xFFFFFFFFu;

  memset(&param, 0, sizeof(param));
  param.execblk_ptr = &execblk_ptr;
  param.argtable_ptr = &argtable_ptr;
  param.flags_ptr = &flags;
  param.instblk_ptr = NULL;
  param.reserved_parm5 = (int *)cppl;
  param.evalblk_ptr = &evalblk_ptr;
  param.reserved_workarea_ptr = NULL;
  param.reserved_userfield_ptr = NULL;
  param.reserved_envblock_ptr = NULL;
  param.rexx_rc_ptr = &rexx_rc;
  param.rexx_rc_ptr = (int *)((unsigned int)param.rexx_rc_ptr | 0x80000000u);

  flags = 0x20000000;
  rc = irxexec(param);
  if (rc != 0) {
    printf("LUZ00019 TSOX failed: irx_rc=%d rexx_rc=%d\n", rc, rexx_rc);
    return 8;
  }
  if (evalblk_to_rc(&evalblk, &eval_rc)) {
    printf("LUZ00018 TSOX rc=%d rexx_rc=%d\n", eval_rc, rexx_rc);
    return eval_rc == 0 ? 0 : 8;
  }
  printf("LUZ00018 TSOX rc=(none) rexx_rc=%d\n", rexx_rc);
  return rexx_rc == 0 ? 0 : 8;
}
