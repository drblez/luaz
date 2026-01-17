# LUZ Message Catalog (3xxxx)

| Code | Message | Context | User Action | Notes |
|------|---------|---------|-------------|-------|
| LUZ30001 | core init not implemented | src/luaz_core.c | Wait for implementation | stub |
| LUZ30002 | core shutdown not implemented | src/luaz_core.c | Wait for implementation | stub |
| LUZ30003 | tso.cmd not implemented | src/luaz_tso.c | Wait for implementation; use JCL/TSO directly | stub |
| LUZ30004 | tso.alloc not implemented | src/luaz_tso.c | Use JCL allocation statements | stub |
| LUZ30005 | tso.free not implemented | src/luaz_tso.c | Free allocations via TSO/JCL | stub |
| LUZ30006 | ds.open_dd not implemented | src/luaz_ds.c | Use DDNAME I/O via JCL tools | stub |
| LUZ30007 | ds.read not implemented | src/luaz_ds.c | Use dataset utilities for reads | stub |
| LUZ30008 | ds.write not implemented | src/luaz_ds.c | Use dataset utilities for writes | stub |
| LUZ30009 | ds.close not implemented | src/luaz_ds.c | None | stub |
| LUZ30010 | ispf.qry not implemented | src/luaz_ispf.c | Verify ISPF setup manually | stub |
| LUZ30011 | ispf.exec not implemented | src/luaz_ispf.c | Use ISPF services via JCL | stub |
| LUZ30012 | axr.request not implemented | src/luaz_axr.c | Use AXR gateway exec | stub |
| LUZ30013 | tls.connect not implemented | src/luaz_tls.c | Use AT‑TLS if available | stub |
| LUZ30014 | tls.listen not implemented | src/luaz_tls.c | Disable TLS server mode | stub |
| LUZ30015 | time backend not implemented | src/luaz_time.c | Build without `LUAZ_TIME_ZOS` or implement time hooks | stub |
| LUZ30016 | localtime backend not implemented | src/luaz_time.c | Build without `LUAZ_TIME_ZOS` or implement time hooks | stub |
| LUZ30017 | gmt backend not implemented | src/luaz_time.c | Build without `LUAZ_TIME_ZOS` or implement time hooks | stub |
| LUZ30018 | policy get not implemented | src/luaz_policy.c | Build without `LUAZ_POLICY` or implement policy hooks | stub |
| LUZ30019 | clock backend not implemented | src/luaz_time.c | Build without `LUAZ_TIME_ZOS` or implement time hooks | stub |
| LUZ30020 | LUAMAP lookup not implemented | src/luaz_path.c | Implement LUAPATH lookup hooks | stub |
| LUZ30021 | LUAPATH load not implemented | src/luaz_path.c | Implement LUAPATH loader hooks | stub |
| LUZ30022 | date formatting not implemented | src/luaz_time.c | Build without `LUAZ_TIME_ZOS` or implement time hooks | stub |
| LUZ30023 | time computation not implemented | src/luaz_time.c | Build without `LUAZ_TIME_ZOS` or implement time hooks | stub |
