# tsostk.asm IBM References

## stack-call

- Passing control to TSO/E I/O service routines (entry point IKJSTCK, R1 points to IOPL).
  https://www.ibm.com/docs/en/zos/3.1.0?topic=io-passing-control-service-routines
- Execute form of the STACK macro instruction (UPT/ECT/ECB, DATASET operands).
  https://www.ibm.com/docs/en/zos/3.1.0?topic=instructions-execute-form-stack-macro-instruction
- List form of the STACK macro instruction (DATASET OUTDD/CLOSE and stack rules).
  https://www.ibm.com/docs/en/zos/3.1.0?topic=instructions-list-form-stack-macro-instruction
- Building the STACK parameter block (STPB) layout and flags.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=instructions-building-stack-parameter-block-stpb
- Command Processor parameter list (CPPL) layout for UPT/ECT pointers.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=routines-command-processor-parameter-list

## stack-stpl

- STPL mapping (STPLUPT/STPLECT/STPLECB/STPLSTPB offsets).
  https://www.ibm.com/docs/en/zos/3.1.0?topic=information-stpl-mapping
- STPB heading info (STPLSTPB points to STPB).
  https://www.ibm.com/docs/en/zos/3.1.0?topic=information-stpb-heading

## stack-outdd-seq

- Execute form DATASET operand allows OUTDD with SEQ to indicate
  sequential output datasets.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=instructions-execute-form-stack-macro-instruction
