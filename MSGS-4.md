# LUZ Message Catalog (4xxxx)

| Code | Message | Context | User Action | Notes |
|------|---------|---------|-------------|-------|
| LUZ-40000 | Reserved for dataset I/O errors | core | Refer to dataset DDNAME and access rights | reserved |
| LUZ-41001 | dynamic loading is disabled on z/OS | lua-vm/src/loadlib.c | Build C modules statically into LUAEXEC | z/OS |
| LUZ-41002 | symbol lookup is disabled on z/OS | lua-vm/src/loadlib.c | Build C modules statically into LUAEXEC | z/OS |
| LUZ-42001 | popen is disabled on z/OS | lua-vm/src/liolib.c | Avoid io.popen; use JCL/TSO for command execution | z/OS |
| LUZ-42002 | file I/O is disabled on z/OS | lua-vm/src/liolib.c | Use DDNAME/dataset I/O via `ds` module | z/OS |
| LUZ-42003 | tmpfile is disabled on z/OS | lua-vm/src/liolib.c | Avoid tmpfile; use datasets or memory buffers | z/OS |
