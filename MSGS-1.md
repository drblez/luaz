# LUZ Message Catalog (1xxxx)

| Code | Message | Context | User Action | Notes |
|------|---------|---------|-------------|-------|
| LUZ10001 | tso.cmd not implemented | lua/tso.lua | Wait for implementation; do not use in production | stub |
| LUZ10002 | tso.alloc not implemented | lua/tso.lua | Wait for implementation; use manual allocation in JCL if needed | stub |
| LUZ10003 | tso.free not implemented | lua/tso.lua | Wait for implementation; free allocations manually | stub |
| LUZ10004 | tso.msg not implemented | lua/tso.lua | Wait for implementation; use TSO/ISPF messaging in JCL | stub |
| LUZ10005 | tso.exit not implemented | lua/tso.lua | Wait for implementation; return RC via JCL step control | stub |
| LUZ11001 | ds.open_dd not implemented | lua/ds.lua | Wait for implementation; use DDNAME I/O via JCL tools | stub |
| LUZ11002 | ds.remove not implemented | lua/ds.lua | Wait for implementation; use dataset utilities | stub |
| LUZ11003 | ds.rename not implemented | lua/ds.lua | Wait for implementation; use dataset utilities | stub |
| LUZ11004 | ds.tmpname not implemented | lua/ds.lua | Wait for implementation; define dataset naming policy | stub |
| LUZ12001 | ispf.qry not implemented | lua/ispf.lua | Wait for implementation; verify ISPF setup manually | stub |
| LUZ12002 | ispf.exec not implemented | lua/ispf.lua | Wait for implementation; run ISPF services via JCL | stub |
| LUZ12003 | ispf.vget not implemented | lua/ispf.lua | Wait for implementation; avoid ISPF variable APIs | stub |
| LUZ12004 | ispf.vput not implemented | lua/ispf.lua | Wait for implementation; avoid ISPF variable APIs | stub |
| LUZ13001 | axr.request not implemented | lua/axr.lua | Wait for implementation; use AXR exec gateway | stub |
| LUZ14001 | tls.connect not implemented | lua/tls.lua | Wait for implementation; use AT‑TLS if available | stub |
| LUZ14002 | tls.listen not implemented | lua/tls.lua | Wait for implementation; disable TLS server mode | stub |
