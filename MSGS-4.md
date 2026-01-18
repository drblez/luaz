# LUZ Message Catalog (4xxxx)

| Code | Message | Context | User Action | Notes |
|------|---------|---------|-------------|-------|
| LUZ40000 | Reserved for dataset I/O errors | core | Refer to dataset DDNAME and access rights | reserved |
| LUZ41001 | dynamic loading is disabled on z/OS | lua-vm/src/loadlib.c | Build C modules statically into LUAEXEC | z/OS |
| LUZ41002 | symbol lookup is disabled on z/OS | lua-vm/src/loadlib.c | Build C modules statically into LUAEXEC | z/OS |
| LUZ42001 | popen is disabled on z/OS | lua-vm/src/liolib.c | Avoid io.popen; use JCL/TSO for command execution | z/OS |
| LUZ42002 | file I/O is disabled on z/OS | lua-vm/src/liolib.c | Use DDNAME/dataset I/O via `ds` module | z/OS |
| LUZ42003 | tmpfile is disabled on z/OS | lua-vm/src/liolib.c | Avoid tmpfile; use datasets or memory buffers | z/OS |
| LUZ43001 | LUAPATH loader not implemented | lua-vm/src/loadlib.c | Use preloaded modules or implement LUAPATH loader | deprecated |
| LUZ43002 | C module loading is disabled on z/OS | lua-vm/src/loadlib.c | Build C modules statically into LUAEXEC | z/OS |
| LUZ44001 | os.execute is disabled on z/OS | lua-vm/src/loslib.c | Use TSO command execution via `tso` module | replaced |
| LUZ44002 | os.remove is disabled on z/OS | lua-vm/src/loslib.c | Use dataset services via `ds` module | replaced |
| LUZ44003 | os.rename is disabled on z/OS | lua-vm/src/loslib.c | Use dataset services via `ds` module | replaced |
| LUZ44004 | os.tmpname is disabled on z/OS | lua-vm/src/loslib.c | Use dataset naming policy or in‑memory buffers | replaced |
| LUZ44005 | os.exit is disabled on z/OS | lua-vm/src/loslib.c | Use `tso.exit` or return RC via host runtime | replaced |
| LUZ44010 | module not available | lua-vm/src/loslib.c | Ensure module is preloaded (tso/ds) | z/OS |
| LUZ44011 | function not available | lua-vm/src/loslib.c | Ensure function exists in module | z/OS |
| LUZ45001 | z/OS time backend not implemented | lua-vm/src/loslib.c | Build without `LUAZ_TIME_ZOS` or implement hooks | legacy |
| LUZ45002 | z/OS gmt conversion not implemented | lua-vm/src/loslib.c | Build without `LUAZ_TIME_ZOS` or implement hooks | legacy |
| LUZ45003 | z/OS localtime conversion not implemented | lua-vm/src/loslib.c | Build without `LUAZ_TIME_ZOS` or implement hooks | legacy |
| LUZ45004 | z/OS strftime failed | lua-vm/src/loslib.c | Check format string and locale settings | legacy |
| LUZ45005 | z/OS mktime not implemented | lua-vm/src/loslib.c | Build without `LUAZ_TIME_ZOS` or implement hooks | legacy |
| LUZ45006 | z/OS clock not implemented | lua-vm/src/loslib.c | Build without `LUAZ_TIME_ZOS` or implement time hooks | legacy |
| LUZ46001 | policy get not implemented | lua-vm/src/loslib.c | Build without `LUAZ_POLICY` or implement policy hooks | z/OS |
| LUZ46002 | policy locale not available | lua-vm/src/loslib.c | Set locale in `LUACONF` policy | z/OS |
| LUZ47001 | invalid module name mapping | lua-vm/src/loadlib.c | Rename module or add LUAMAP entry | z/OS |
| LUZ47002 | LUAMAP entry not found | lua-vm/src/loadlib.c | Add entry to LUAMAP in LUAPATH PDS | z/OS |
| LUZ47003 | LUAPATH load failed | lua-vm/src/loadlib.c | Ensure member exists and LUAPATH is allocated | z/OS |
| LUZ47004 | module load error | lua-vm/src/loadlib.c | Check module source and encoding | z/OS |
| LUZ40010 | invalid arguments | src/hashcmp.c | Pass mode (C/U), member, source PDS, and hash PDS | build |
| LUZ40011 | unable to open source member | src/hashcmp.c | Verify SRCIN DD, member name, and SRC PDS allocation | build |
| LUZ40012 | hash member missing or unreadable | src/hashcmp.c | Ensure hash PDSE exists and member is readable | build |
| LUZ40013 | hash mismatch | src/hashcmp.c | Recompile module to refresh hash | build |
| LUZ40014 | unable to update hash member | src/hashcmp.c | Verify HASHOUT DD, PDSE allocation, and write access | build |
| LUZ40015 | hash record format invalid | src/hashcmp.c | Regenerate hash member or delete it to force rebuild | build |
