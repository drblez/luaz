# ds.c reference notes

## IBM documentation references

- z/OS XL C/C++ User's Guide: "File names for MVS data sets: Using a data set name"
  - https://www.ibm.com/docs/en/SSLTBW_3.1.0/com.ibm.zos.v3r1.cbcpg01/cbc1p281.htm
  - Notes: MVS data set names for C runtime file operations use the `//'<dsn>'` form; single quotes indicate a fully-qualified DSN, and the leading `//` marks MVS dataset syntax.

- z/OS XL C/C++ User's Guide: "fldata() behavior" (MVS data set streams)
  - https://www.ibm.com/docs/en/zos/2.5.0/com.ibm.zos.v2r5.cbcpx01/cbc1p2168.htm
  - Notes: Provides `fldata_t` structure fields for dataset metadata, including RECFM/DSORG flags, BLKSIZE, and MAXRECLEN.

- z/OS XL C/C++ User's Guide: "How to specify RECFM, LRECL, and BLKSIZE"
  - https://www.ibm.com/docs/en/zos/2.5.0/com.ibm.zos.v2r5.cbcpx01/fmtspec.htm
  - Notes: `recfm=*` on `fopen()` forces use of existing dataset attributes for existing DASD datasets.
