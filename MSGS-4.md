# LUZ Message Catalog (4xxxx)

| Code | Message | Context | User Action | Notes |
|------|---------|---------|-------------|-------|
| LUZ-40000 | Reserved for dataset I/O errors | core | Refer to dataset DDNAME and access rights | reserved |
| LUZ-41001 | dynamic loading is disabled on z/OS | lua-vm/src/loadlib.c | Build C modules statically into LUAEXEC | z/OS |
| LUZ-41002 | symbol lookup is disabled on z/OS | lua-vm/src/loadlib.c | Build C modules statically into LUAEXEC | z/OS |
| LUZ-42001 | popen is disabled on z/OS | lua-vm/src/liolib.c | Avoid io.popen; use JCL/TSO for command execution | z/OS |
| LUZ-42002 | file I/O is disabled on z/OS | lua-vm/src/liolib.c | Use DDNAME/dataset I/O via `ds` module | z/OS |
| LUZ-42003 | tmpfile is disabled on z/OS | lua-vm/src/liolib.c | Avoid tmpfile; use datasets or memory buffers | z/OS |
| LUZ-43001 | LUAPATH loader not implemented | lua-vm/src/loadlib.c | Use preloaded modules or implement LUAPATH loader | z/OS |
| LUZ-43002 | C module loading is disabled on z/OS | lua-vm/src/loadlib.c | Build C modules statically into LUAEXEC | z/OS |
| LUZ-44001 | os.execute is disabled on z/OS | lua-vm/src/loslib.c | Use TSO command execution via `tso` module | z/OS |
| LUZ-44002 | os.remove is disabled on z/OS | lua-vm/src/loslib.c | Use dataset services via `ds` module | z/OS |
| LUZ-44003 | os.rename is disabled on z/OS | lua-vm/src/loslib.c | Use dataset services via `ds` module | z/OS |
| LUZ-44004 | os.tmpname is disabled on z/OS | lua-vm/src/loslib.c | Use dataset naming policy or in‑memory buffers | z/OS |
| LUZ-44005 | os.exit is disabled on z/OS | lua-vm/src/loslib.c | Use `tso.exit` or return RC via host runtime | z/OS |
| LUZ-45001 | z/OS time backend not implemented | lua-vm/src/loslib.c | Build without `LUAZ_TIME_ZOS` or implement hooks | z/OS |
| LUZ-45002 | z/OS gmt conversion not implemented | lua-vm/src/loslib.c | Build without `LUAZ_TIME_ZOS` or implement hooks | z/OS |
| LUZ-45003 | z/OS localtime conversion not implemented | lua-vm/src/loslib.c | Build without `LUAZ_TIME_ZOS` or implement hooks | z/OS |
| LUZ-45004 | z/OS strftime failed | lua-vm/src/loslib.c | Check format string and locale settings | z/OS |
| LUZ-45005 | z/OS mktime not implemented | lua-vm/src/loslib.c | Build without `LUAZ_TIME_ZOS` or implement hooks | z/OS |
