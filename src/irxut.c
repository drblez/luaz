/*
 * Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
 *
 * IRXEXEC unit test helper based on IBM EAGGXC (calling IRXEXEC from C).
 *
 * Object Table:
 * | Object | Kind | Purpose |
 * |--------|------|---------|
 * | main | function | Invoke IRXEXEC against HELLO exec and validate RC |
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#pragma linkage(fetch, OS)
extern void (*fetch(const char *name))();

typedef int (*funcPtr)();

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

int main(void)
{
  funcPtr fetched;
  IRXEXEC_type param;
  EXECBLK_type execblk;
  EXECBLK_type *execblk_ptr = &execblk;
  EVALBLK_type evalblk;
  EVALBLK_type *evalblk_ptr = &evalblk;
  one_parameter_type args[2];
  one_parameter_type *argtable_ptr = &args[0];
  char arg1 = '3';
  int flags = 0;
  int rexx_rc = 0;
  int ret_val = 0;
  int irx_rc = 0;
  char eval_str[256];

  fetched = (funcPtr)fetch("IRXEXEC");
  if (fetched == NULL) {
    puts("LUZ00014 IRXEXEC UT failed: fetch IRXEXEC");
    return 8;
  }

  memset(&execblk, 0, sizeof(execblk));
  strcpy(execblk.EXECBLK_ACRYN, "IRXEXECB");
  execblk.EXECBLK_LENGTH = 48;
  execblk.EXECBLK_reserved = 0;
  strcpy(execblk.EXECBLK_MEMBER, "HELLO");
  strcpy(execblk.EXECBLK_DDNAME, "SYSEXEC");
  strcpy(execblk.EXECBLK_SUBCOM, "TSO");
  execblk.EXECBLK_DSNPTR = 0;
  execblk.EXECBLK_DSNLEN = 0;

  memset(&evalblk, 0, sizeof(evalblk));
  evalblk.EVALBLK_EVSIZE = 34;
  evalblk.EVALBLK_EVLEN = 0;

  args[0].ARGSTRING_PTR = &arg1;
  args[0].ARGSTRING_LENGTH = 1;
  args[1].ARGSTRING_PTR = (void *)0xFFFFFFFFu;
  args[1].ARGSTRING_LENGTH = (int)0xFFFFFFFFu;

  memset(&param, 0, sizeof(param));
  param.execblk_ptr = &execblk_ptr;
  param.argtable_ptr = &argtable_ptr;
  param.flags_ptr = &flags;
  param.instblk_ptr = NULL;
  param.reserved_parm5 = NULL;
  param.evalblk_ptr = &evalblk_ptr;
  param.reserved_workarea_ptr = NULL;
  param.reserved_userfield_ptr = NULL;
  param.reserved_envblock_ptr = NULL;
  param.rexx_rc_ptr = &rexx_rc;
  param.rexx_rc_ptr = (int *)((unsigned int)param.rexx_rc_ptr | 0x80000000u);

  flags = 0x40000000;
  rexx_rc = 0;

  irx_rc = (*fetched)(param);
  if (irx_rc != 0) {
    printf("LUZ00014 IRXEXEC UT failed: irx_rc=%d rexx_rc=%d\n", irx_rc, rexx_rc);
    return 8;
  }
  if (evalblk.EVALBLK_EVLEN <= 0 || evalblk.EVALBLK_EVLEN >= (int)sizeof(eval_str)) {
    printf("LUZ00014 IRXEXEC UT failed: eval_len=%d rexx_rc=%d\n", evalblk.EVALBLK_EVLEN, rexx_rc);
    return 8;
  }
  memcpy(eval_str, evalblk.EVALBLK_EVDATA, (size_t)evalblk.EVALBLK_EVLEN);
  eval_str[evalblk.EVALBLK_EVLEN] = '\0';
  {
    int i = 0;
    ret_val = 0;
    for (; i < evalblk.EVALBLK_EVLEN; i++) {
      unsigned char c = (unsigned char)evalblk.EVALBLK_EVDATA[i];
      if (c < 0xF0 || c > 0xF9)
        break;
      ret_val = (ret_val * 10) + (c - 0xF0);
    }
    if (i == 0) {
      printf("LUZ00014 IRXEXEC UT failed: eval not numeric rexx_rc=%d\n", rexx_rc);
      return 8;
    }
  }
  if (ret_val != 3) {
    unsigned int b0 = (unsigned char)evalblk.EVALBLK_EVDATA[0];
    unsigned int b1 = (unsigned char)evalblk.EVALBLK_EVDATA[1];
    printf("LUZ00014 IRXEXEC UT failed: eval='%s' len=%d hex=%02X%02X rexx_rc=%d\n",
           eval_str, evalblk.EVALBLK_EVLEN, b0, b1, rexx_rc);
    return 8;
  }

  puts("LUZ00013 IRXEXEC UT OK");
  return 0;
}
