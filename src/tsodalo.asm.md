# tsodalo.asm IBM References

## dair-outdd-only

- Requesting dynamic allocation functions (DAIR/SVC 99 request blocks).
  https://www.ibm.com/docs/en/zos/3.2.0?topic=guide-requesting-dynamic-allocation-functions

## dair-dcb-copy

- Allocating a data set by dsname (DAIR entry code X'08'), DA08ALN field.
  https://www.ibm.com/docs/en/zos/2.5.0?topic=dpbd-allocating-data-set-by-dsname-entry-code-x08

## dair-utility-name

- Allocating a data set by dsname (DAIR entry code X'08'), utility dsname
  form &name (length within 8 characters after &).
  https://www.ibm.com/docs/en/zos/2.5.0?topic=dpbd-allocating-data-set-by-dsname-entry-code-x08

## dair-return-ddname

- Allocating a data set by dsname (DAIR entry code X'08'), DA08DDN field
  indicates DAIR-generated DDNAME when blanks are supplied.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=dpbd-allocating-data-set-by-dsname-entry-code-x08

## dair-daplecb

- The DAIR parameter list (DAPL) requires DAPLECB to point to a caller
  ECB word initialized to zero.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=dair-parameter-list-dapl

## dair-space-qty

- DA08PQTY/DA08SQTY require the high-order byte set to zero and the
  low-order three bytes containing a binary quantity.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=dpbd-allocating-data-set-by-dsname-entry-code-x08

## dair-blank-fields

- Optional character fields (DDNAME, UNIT, SER, MNM, PSWD) must be
  padded with blanks when omitted.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=dpbd-allocating-data-set-by-dsname-entry-code-x08

## dair-rc-r15

- DAIR returns the primary return code in register 15; DARC/CTRC are
  auxiliary fields used when RC=12/8.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=dair-return-codes-from

## dair-attr-list

- Associating DCB parameters with a specified name (DAIR entry code X'34').
  https://www.ibm.com/docs/en/zos/2.5.0?topic=dpbd-associating-dcb-parameters-specified-name-entry-code-x34
- The DAIR attribute control block (DAIRACB) layout.
  https://www.ibm.com/docs/en/zos/2.5.0?topic=dapb-dair-attribute-control-block-dairacb

## ceeppa-multi-entry

- CEEPPA multi-entry layout and PPA2 guidance.
  https://www.ibm.com/docs/en/zos/3.1.0?topic=macros-ceeppa-macro-generate-ppa
