# tso.c IBM References

## ikjeftsr-parameter-list

- IKJEFTSR parameter list, optional parameters 7-9, and HOB requirement.
  https://www.ibm.com/docs/en/zos/2.4.0?topic=ikjeftsr-parameter-list
- Passing control to IKJEFTSR and parameter list termination rules.
  https://www.ibm.com/docs/en/zos/2.4.0?topic=ikjeftsr-passing-control

## ikjeftsr-param8-cppl

- Parameter 8 uses the CPPL (four fullwords) when invoking commands in an
  unauthorized environment.
  https://www.ibm.com/docs/en/zos/2.4.0?topic=ikjeftsr-parameter-list
- CPPL layout and purpose (four-word parameter list from TMP).
  https://www.ibm.com/docs/en/zos/2.4.0?topic=environment-command-processor-parameter-list-cppl

## ikjeftsr-rc-mapping

- Return codes from IKJEFTSR (RC 0/4/8/12/16/20/24/28 meanings).
  https://www.ibm.com/docs/en/zos/2.4.0?topic=ikjeftsr-return-codes-from
- Reason codes from IKJEFTSR when RC=20 (parameter list errors).
  https://www.ibm.com/docs/en/zos/2.4.0?topic=ikjeftsr-reason-codes-from

## tso-alloc-command

- TSO ALLOCATE command examples for new sequential datasets (DSORG/SPACE/RECFM).
  https://www.ibm.com/docs/en/zos/2.4.0?topic=sets-allocating-data-tso-allocate-command
- DSORG/RECFM/LRECL/BLKSIZE operands for ALLOCATE.
  https://www.ibm.com/docs/en/zos/2.1.0?topic=set-dsorg-recfm-lrecl-blksize-operands
- REUSE operand to reassign an already allocated DDNAME.
  https://www.ibm.com/docs/en/zos/2.1.0?topic=set-reuse-operand
- FREE command operands (DELETE disposition).
  https://www.ibm.com/docs/en/zos/2.4.0?topic=command-free-operands

## tso-temp-dsn

- Temporary DSN naming rules (DSNAME=&&name for dynamic allocation).
  https://www.ibm.com/docs/en/zos/2.4.0?topic=definition-data-set-name-temporary-data-set

## tso-stack-outdd

- Passing control to TSO/E I/O service routines (entry point IKJSTCK).
  https://www.ibm.com/docs/en/zos/3.1.0?topic=io-passing-control-service-routines
- Execute form of the STACK macro instruction (UPT/ECT/ECB, DATASET OUTDD/CLOSE).
  https://www.ibm.com/docs/en/zos/3.1.0?topic=instructions-execute-form-stack-macro-instruction
- List form of the STACK macro instruction (DATASET OUTDD/CLOSE and stack rules).
  https://www.ibm.com/docs/en/zos/3.1.0?topic=instructions-list-form-stack-macro-instruction
- Building the STACK parameter block (STPB) layout and flags.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=instructions-building-stack-parameter-block-stpb
- Command Processor parameter list (CPPL) layout for UPT/ECT pointers.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=routines-command-processor-parameter-list

## tso-dair-outdd

- DAIR (SVC 99) request block guidance for dynamic allocation.
  https://www.ibm.com/docs/en/zos/3.2.0?topic=guide-requesting-dynamic-allocation-functions

## os-linkage-plist

- OS linkage parameter lists: HOB on last parameter and address vs value
  parameter behavior in plist construction.
  https://www.ibm.com/docs/en/zos/2.4.0?topic=programs-parameter-lists-os-linkage

## tso-rexx-outtrap

- OUTTRAP function (TSO/E REXX) for trapping command output.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=tef-outtrap
