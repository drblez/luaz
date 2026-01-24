# ftp_submit.sh: FTP delete for rebuild

## ftp-delete

Purpose: delete OBJ and HASH PDSE members over FTP before BUILDINC
submission so the incremental build forces recompilation.

IBM documentation reference:
- FTP DELE command error example shows dataset/member delete syntax:
  https://www.ibm.com/docs/en/zos/2.5.0?topic=codes-550-could-not-delete-dataset

Notes:
- Prefix rebuild members:
  - `C:MOD` deletes OBJ and `HLQ.LUA.SRC.HASHES(MOD)`.
  - `A:MOD` deletes OBJ and `HLQ.LUA.ASM.HASHES(MOD)`.
  - `MOD` (no prefix) deletes OBJ and both hash members.
- Non-fatal FTP errors are logged as warnings (missing members, etc.).
