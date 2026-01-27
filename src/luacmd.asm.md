# IBM References for src/luacmd.asm

## snapx-pre-luaexrun

Source: IBM z/OS MVS Programming: Authorized Assembler Services Guide.

- SNAPX execute form syntax (STORAGE with register addresses):
  https://www.ibm.com/docs/en/zos/3.1.0?topic=continue-snap-snapxexecute-form
- SNAPX list form syntax (PDATA/STORAGE semantics):
  https://www.ibm.com/docs/en/zos/3.1.0?topic=continue-snap-snapxlist-form
- SNAP dump DCB requirements (RECFM/LRECL/BLKSIZE/MACRF, OPEN before SNAPX):
  https://www.ibm.com/docs/en/zos/3.1.0?topic=dump-obtaining-snap-dumps

These references document SNAPX usage and DCB attributes for the
LUACMD pre-call dump just before CEEPIPI call_sub invokes LUAEXRUN.

## open-return-codes

Source: IBM z/OS DFSMS Macro Instructions for Data Sets (QSAM OPEN).

- OPEN return codes (R15 meanings and warnings):
  https://www.ibm.com/docs/en/zos/3.1.0?topic=qsam-open-return-codes

This reference documents the OPEN macro return codes used to decide
whether SNAP output can proceed when OPEN returns a warning RC.

## cee-runtime-options

Source: IBM z/OS Language Environment Programming Reference.

- TERMTHDACT option behavior (UADUMP triggers CEEDUMP via CEE3DMP):
  https://www.ibm.com/docs/en/zos/2.5.0?topic=options-termthdact
- CEEPIPI init_sub runtime options parameter (PRTMOPT):
  https://www.ibm.com/docs/en/zos/2.5.0?topic=initialization-init-sub-initialize-subroutines

These references document the runtime options passed via PRTMOPT for
CEEPIPI init_sub so CEEDUMP/trace data are emitted on abnormal
termination.
