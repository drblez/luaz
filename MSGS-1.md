# LUZ Message Catalog (1xxxx)

| Code | Message | Context | User Action | Notes |
|------|---------|---------|-------------|-------|
| LUZ-10001 | tso.cmd not implemented | lua/tso.lua | Wait for implementation; do not use in production | stub |
| LUZ-10002 | tso.alloc not implemented | lua/tso.lua | Wait for implementation; use manual allocation in JCL if needed | stub |
| LUZ-10003 | tso.free not implemented | lua/tso.lua | Wait for implementation; free allocations manually | stub |
| LUZ-10004 | tso.msg not implemented | lua/tso.lua | Wait for implementation; use TSO/ISPF messaging in JCL | stub |
| LUZ-10005 | tso.exit not implemented | lua/tso.lua | Wait for implementation; return RC via JCL step control | stub |
| LUZ-11001 | ds.open_dd not implemented | lua/ds.lua | Wait for implementation; use DDNAME I/O via JCL tools | stub |
| LUZ-11002 | ds.remove not implemented | lua/ds.lua | Wait for implementation; use dataset utilities | stub |
| LUZ-11003 | ds.rename not implemented | lua/ds.lua | Wait for implementation; use dataset utilities | stub |
| LUZ-11004 | ds.tmpname not implemented | lua/ds.lua | Wait for implementation; define dataset naming policy | stub |
| LUZ-12001 | ispf.qry not implemented | lua/ispf.lua | Wait for implementation; verify ISPF setup manually | stub |
| LUZ-12002 | ispf.exec not implemented | lua/ispf.lua | Wait for implementation; run ISPF services via JCL | stub |
| LUZ-12003 | ispf.vget not implemented | lua/ispf.lua | Wait for implementation; avoid ISPF variable APIs | stub |
| LUZ-12004 | ispf.vput not implemented | lua/ispf.lua | Wait for implementation; avoid ISPF variable APIs | stub |
| LUZ-13001 | axr.request not implemented | lua/axr.lua | Wait for implementation; use AXR exec gateway | stub |
| LUZ-14001 | tls.connect not implemented | lua/tls.lua | Wait for implementation; use AT‑TLS if available | stub |
| LUZ-14002 | tls.listen not implemented | lua/tls.lua | Wait for implementation; disable TLS server mode | stub |
