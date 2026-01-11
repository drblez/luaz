//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Sample ISPF in batch with ISPSTART
//*
//* Object Table:
//* | Step | Purpose |
//* |------|---------|
//* | ISPFBAT | Start ISPF environment and invoke LUAEXEC |
//*
//ISPFBAT EXEC PGM=IKJEFT01
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  ISPSTART CMD(LUAEXEC)
/*
