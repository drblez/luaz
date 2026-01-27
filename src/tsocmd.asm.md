# IBM References for src/tsocmd.asm

## snapx-pre-ikjeftsr

Source: IBM z/OS MVS Programming: Authorized Assembler Services Guide.

- SNAPX execute form syntax (STORAGE with register addresses):
  https://www.ibm.com/docs/en/zos/3.1.0?topic=continue-snap-snapxexecute-form
- SNAPX list form syntax (PDATA/STORAGE semantics):
  https://www.ibm.com/docs/en/zos/3.1.0?topic=continue-snap-snapxlist-form
- SNAP dump DCB requirements (RECFM/LRECL/BLKSIZE/MACRF, OPEN before SNAPX):
  https://www.ibm.com/docs/en/zos/3.1.0?topic=dump-obtaining-snap-dumps

These references document the SNAPX execute-form usage and the DCB
attributes required to emit a SNAP dump from TSOCMD before IKJEFTSR.

## open-return-codes

Source: IBM z/OS DFSMS Macro Instructions for Data Sets (QSAM OPEN).

- OPEN return codes (R15 meanings and warnings):
  https://www.ibm.com/docs/en/zos/3.1.0?topic=qsam-open-return-codes

This reference documents the OPEN macro return codes used to decide
whether SNAP output can proceed when OPEN returns a warning RC.

## espie-tsodalc-abend

Source: IBM z/OS MVS Programming: Assembler Services Guide / Authorized
Assembler Services Reference.

- ESPIE SET option (establish exit, interruption list, PARAM list):
  https://www.ibm.com/docs/en/zos/2.4.0?topic=spie-espie-set-option
- ESPIE RESET option (restore previous ESPIE environment):
  https://www.ibm.com/docs/en/zos/2.4.0?topic=spie-espie-reset-option
- Environment on entry to SPIE/ESPIE exit (R1 -> PIE/EPIE, regs):
  https://www.ibm.com/docs/en/zos/2.3.0?topic=routines-environment-upon-entry-users-exit-routine
- Requesting percolation from an ESPIE exit (EPIEPERC/EPIERSET):
  https://www.ibm.com/docs/en/zos/2.4.0?topic=routines-requesting-percolation-from-espie-exit
- EPIE control block (EPIEFLGS/EPIEPERC/EPIERTOK offsets):
  https://www.ibm.com/docs/en/zos/2.5.0?topic=iar-epie-information

These references document ESPIE SET/RESET usage and the register
environment for the ESPIE exit that captures SNAPX diagnostics during
TSODALC.
