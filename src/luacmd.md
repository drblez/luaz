# LUACMD: CEEPIPI preinitialization

## ceepipi-preinit

Purpose:
- Replace direct LE entry from a non-LE TSO command processor with
  Language Environment preinitialization (CEEPIPI init_sub/call_sub/term).

Rationale:
- IBM notes that assembler programs must not call CEESTART/CEEMAIN
  directly as standard entry points; results are unpredictable.
- Preinitialization is the supported way to create and reuse a common
  LE runtime environment from a non-LE driver.

IBM references:
- CEESTART/CEEMAIN restrictions for assembler:
  https://www.ibm.com/docs/en/zos/2.3.0?topic=routines-ceestart-ceemain-ceefmain
- Using preinitialization (CEEPIPI overview):
  https://www.ibm.com/docs/en/zos/2.5.0?topic=services-using-preinitialization

## debug-trace

Purpose:
- LUACMD emits SNAPX before LUAEXRUN call_sub to capture the CEEPIPI
  call_sub context, plist state, and line buffer just before entering
  LE.

Notes:
- SNAPX output is written to DD SNAP in the invoking JCL (see ITTSO
  job). 
- Detailed SNAPX references are tracked in `src/luacmd.asm.md`.

## ceepipi-init-sub

IBM references:
- (init_sub) parameter list and behavior:
  https://www.ibm.com/docs/en/zos/2.5.0?topic=initialization-init-sub-initialize-subroutines

## ceepipi-runtime-options

Purpose:
- Provide explicit LE runtime options (TRAP/TERMTHDACT/RPTOPTS) to
  ensure CEEDUMP/trace data is emitted when the preinit enclave
  abends.

IBM references:
- TERMTHDACT option behavior (UADUMP triggers CEEDUMP via CEE3DMP):
  https://www.ibm.com/docs/en/zos/2.5.0?topic=options-termthdact

## ceepipi-call-sub

IBM references:
- (call_sub) parameter list and behavior (parm_ptr placed into R1 for
  the invoked routine):
  https://www.ibm.com/docs/en/zos/2.5.0?topic=invocation-call-sub-subroutines

## ceepipi-term

IBM references:
- (term) parameter list and behavior:
  https://www.ibm.com/docs/en/zos/2.5.0?topic=invocation-term-terminate-environment

## ceepipi-preinit-table

IBM references:
- Example PreInit table usage and CEEPIPI driver sample:
  https://www.ibm.com/docs/en/zos/2.5.0?topic=services-example-program-invocation-ceepipi

## ceexpity-entry-point

Purpose:
- Document CEEXPITY entry_point semantics for PreInit tables used by LUACMD.

Key points:
- `entry_point=0` means Language Environment dynamically loads a module
  by the 8-character `name`.
- If `entry_point` is present, it is used as the routine address and
  `name` is ignored.
- The high-order bit of `entry_point` must be set to indicate AMODE 31.

IBM references:
- CEEXPITY macro (entry_point semantics and AMODE bit):
  https://www.ibm.com/docs/en/zos/3.1.0?topic=table-ceexpity

## os-linkage-plist

Purpose:
- Document OS-linkage parameter list rules used by LUACMD when calling
  LUAEXRUN (C) from non-LE assembler via CEEPIPI call_sub.

Key points (IBM):
- OS linkage parameter lists are lists of pointers.
- For address-type parameters, the address itself is stored in the list.
- For value parameters, a copy is created and the address of the copy
  is stored in the list.
- The high-order bit of the last parameter in the list is turned on
  by the compiler; LUACMD mirrors this for compatibility.
- LUAEXRUN receives three parameters: line address (address param),
  line length cell address (value param), and CPPL address (address param).

IBM references:
- Parameter lists for OS linkage:
  https://www.ibm.com/docs/en/zos/2.5.0?topic=programs-parameter-lists-os-linkage
