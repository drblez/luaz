# LUZ Message Catalog (3xxxx)

| Code | Message | Context | User Action | Notes |
|------|---------|---------|-------------|-------|
| LUZ30001 | core init not implemented | src/core.c | Wait for implementation | stub |
| LUZ30002 | core shutdown not implemented | src/core.c | Wait for implementation | stub |
| LUZ30003 | tso.cmd bridge unavailable | src/tso.c | Ensure SYSEXEC includes LUTSO and IRXEXEC is available | internal |
| LUZ30004 | tso.alloc bridge unavailable | src/tso.c | Ensure SYSEXEC includes LUTSO and IRXEXEC is available | internal |
| LUZ30005 | tso.free bridge unavailable | src/tso.c | Ensure SYSEXEC includes LUTSO and IRXEXEC is available | internal |
| LUZ30024 | tso.msg invalid input | src/tso.c | Provide a non-empty message string | validation |
| LUZ30025 | tso.exit invalid input | src/tso.c | Provide a numeric RC | validation |
| LUZ30030 | tso.msg output | src/tso.c | None | emitted |
| LUZ30031 | tso.cmd output line | src/tso.c | Use `tso.cmd` output table to consume lines | emitted |
| LUZ30032 | tso.cmd failed (irx_rc/rexx_rc in message) | src/tso.c | Check IKJTSOEV init, IRXEXEC availability, and LUTSO in SYSEXEC | runtime |
| LUZ30033 | tso.alloc failed (irx_rc/rexx_rc in message) | src/tso.c | Check IKJTSOEV init and ALLOC spec | runtime |
| LUZ30034 | tso.free failed (irx_rc/rexx_rc in message) | src/tso.c | Ensure DDNAME is allocated and IKJTSOEV init succeeded | runtime |
| LUZ30035 | tso.msg failed (irx_rc/rexx_rc in message) | src/tso.c | Ensure IKJTSOEV init and message string are valid | runtime |
| LUZ30036 | LUTSO invalid mode | rexx/LUTSO.rexx | Use supported modes CMD/ALLOC/FREE/MSG | validation |
| LUZ30006 | ds.open_dd not implemented | src/ds.c | Use DDNAME I/O via JCL tools | stub |
| LUZ30007 | ds.read not implemented | src/ds.c | Use dataset utilities for reads | stub |
| LUZ30008 | ds.write not implemented | src/ds.c | Use dataset utilities for writes | stub |
| LUZ30009 | ds.close not implemented | src/ds.c | None | stub |
| LUZ30010 | ispf.qry not implemented | src/ispf.c | Verify ISPF setup manually | stub |
| LUZ30011 | ispf.exec not implemented | src/ispf.c | Use ISPF services via JCL | stub |
| LUZ30012 | axr.request not implemented | src/axr.c | Use AXR gateway exec | stub |
| LUZ30013 | tls.connect not implemented | src/tls.c | Use AT‑TLS if available | stub |
| LUZ30014 | tls.listen not implemented | src/tls.c | Disable TLS server mode | stub |
| LUZ30015 | time backend not implemented | src/time.c | Build without `LUAZ_TIME_ZOS` or implement time hooks | stub |
| LUZ30016 | localtime backend not implemented | src/time.c | Build without `LUAZ_TIME_ZOS` or implement time hooks | stub |
| LUZ30017 | gmt backend not implemented | src/time.c | Build without `LUAZ_TIME_ZOS` or implement time hooks | stub |
| LUZ30018 | policy get not implemented | src/policy.c | Build without `LUAZ_POLICY` or implement policy hooks | stub |
| LUZ30019 | clock backend not implemented | src/time.c | Build without `LUAZ_TIME_ZOS` or implement time hooks | stub |
| LUZ30020 | LUAMAP lookup not implemented | src/path.c | Implement LUAPATH lookup hooks | stub |
| LUZ30021 | LUAPATH load not implemented | src/path.c | Implement LUAPATH loader hooks | stub |
| LUZ30022 | date formatting not implemented | src/time.c | Build without `LUAZ_TIME_ZOS` or implement time hooks | stub |
| LUZ30023 | time computation not implemented | src/time.c | Build without `LUAZ_TIME_ZOS` or implement time hooks | stub |
