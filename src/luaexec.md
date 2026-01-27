# luaexec.c IBM References

## luain-record-io

- Record I/O is an XL C/C++ extension; for record-format files it reads and
  writes one record at a time and allows only `fread`/`fwrite` for I/O.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=output-record-io
- `fopen` parameters support `type=record` and dataset DCB qualifiers such as
  `recfm=` and `lrecl=` for record files.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=of-fopen-freopen-parameters

## le-condition-handler

- CEEHDLR registration pattern and handler signature in C/C++ examples.
  https://www.ibm.com/docs/en/zos/2.5.0?topic=pli-cc-examples-using-ceehdlr-ceegtst-ceeczst-ceemrcr
- CEEITOK returns the initial condition token for the active condition.
  https://www.ibm.com/docs/en/zos/2.5.0?topic=services-ceeitokreturn-initial-condition-token
- CEEDCOD decomposes a condition token into c1/c2/case/severity/facility.
  https://www.ibm.com/docs/en/zos/2.5.0?topic=services-ceedcoddecompose-condition-token
- CEEGQDT retrieves q_data_token from the ISI for a condition token.
  https://www.ibm.com/docs/en/zos/2.5.0?topic=services-ceegqdtretrieve-q-data-token
- q_data layout for abends (parm count, abend code, reason code).
  https://www.ibm.com/docs/en/zos/2.5.0?topic=tokens-q-data-structure-abends
