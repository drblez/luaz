# luait.c IBM References

## luain-record-io

- Record I/O is an XL C/C++ extension; for record-format files it reads and
  writes one record at a time and allows only `fread`/`fwrite` for I/O.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=output-record-io
- `fopen` parameters support `type=record` and dataset DCB qualifiers such as
  `recfm=` and `lrecl=` for record files.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=of-fopen-freopen-parameters
