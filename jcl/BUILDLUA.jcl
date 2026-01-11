//* Copyright 2026 drblez AKA Ruslan Stepanenko (drblez@gmail.com)
//* Purpose: Build LUAEXEC load module (compile + link-edit)
//*
//* Object Table:
//* | Step | Purpose |
//* |------|---------|
//* | CC     | Compile C sources to object modules |
//* | LKED   | Link-edit LUAEXEC load module |
//*
//CC     EXEC PGM=IGYCRCTL,PARM='C99,LIB'
//SYSPRINT DD  SYSOUT=*
//SYSOUT   DD  SYSOUT=*
//SYSIN    DD  *
  /* TODO: Put C source (or include via SYSIN DD concatenation) */
/*
//SYSLIN   DD  DSN=&&OBJ,DISP=(MOD,PASS),UNIT=SYSDA,
//             SPACE=(TRK,(10,10))
//SYSUT1   DD  UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT2   DD  UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT3   DD  UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT4   DD  UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT5   DD  UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT6   DD  UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT7   DD  UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT8   DD  UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSLIB   DD  DSN=CEE.SCEELKED,DISP=SHR
//*
//LKED   EXEC PGM=HEWL,PARM='LET,MAP,XREF'
//SYSPRINT DD SYSOUT=*
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSLIN   DD DSN=&&OBJ,DISP=(OLD,DELETE)
//SYSLMOD  DD DSN=DRBLEZ.LUA.LOAD(LUAEXEC),DISP=SHR
//SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR
