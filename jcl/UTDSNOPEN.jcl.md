# UTDSNOPEN.jcl reference notes

## IBM documentation references

- z/OS MVS JCL Reference: Using symbols in JES in-stream data
  - https://www.ibm.com/docs/en/zos/2.5.0?topic=symbols-using-in-jes-in-stream-data
  - Notes: `SYMBOLS=JCLONLY` on DD * enables substitution of JCL symbols in in-stream data; JCL symbols set by `SET` must be `EXPORT`ed to be available at execution time.
