# ITTSO: LE runtime traces (CEEOPTS)

## ceeopts-trace

Purpose: enable IBM Language Environment runtime tracing for batch runs
of ITTSO, forcing CEEDUMP output with trace tables (no SYSMDUMP).

Options used in `jcl/ITTSO.jcl`:
- RPTOPTS(ON)
- RPTSTG(ON)
- TRAP(ON,SPIE)
- ABTERMENC(ABEND)
- TERMTHDACT(UADUMP)
- TRACE(ON,256K,DUMP,LE=1)

Required DDs in `jcl/ITTSO.jcl`:
- CEEDUMP DD (SYSOUT=*) to capture the LE trace table/traceback.
- SYSABEND DD (SYSOUT=*) for formatted system dumps when needed.

IBM documentation:
- Runtime options overview (includes TRAP/TERMTHDACT/TRACE):
  https://www.ibm.com/docs/en/zos/2.5.0?topic=pya6ad-using-language-environment-runtime-options
- TRACE option:
  https://www.ibm.com/docs/en/zos/3.1.0?topic=ulero-trace
- CEEOPTS DD card usage:
  https://www.ibm.com/docs/en/zos/2.5.0?topic=batch-specifying-runtime-options-ceeopts-dd-card
- CEEDUMP report options:
  https://www.ibm.com/docs/en/zos/2.5.0?topic=ulero-ceedump
- TERMTHDACT dump destinations:
  https://www.ibm.com/docs/en/zos/2.5.0?topic=dumps-generating-language-environment-dump-termthdact
