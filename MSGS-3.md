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
| LUZ30032 | tso.cmd failed (native reason/abend/dair_rc or irx_rc/rexx_rc in message) | src/tso.c | Check TMP/DAIR setup or IRXEXEC/LUTSO fallback status | runtime |
| LUZ30033 | tso.alloc failed (irx_rc/rexx_rc in message) | src/tso.c | Check IKJTSOEV init and ALLOC spec | runtime |
| LUZ30034 | tso.free failed (irx_rc/rexx_rc in message) | src/tso.c | Ensure DDNAME is allocated and IKJTSOEV init succeeded | runtime |
| LUZ30035 | tso.msg failed (irx_rc/rexx_rc in message) | src/tso.c | Ensure IKJTSOEV init and message string are valid | runtime |
| LUZ30036 | LUTSO invalid mode | rexx/LUTSO.rexx | Use supported modes CMD/ALLOC/FREE/MSG | validation |
| LUZ30040 | LUAEXEC init failed | src/luaexec.c | Verify LE runtime availability and memory | runtime |
| LUZ30041 | LUAEXEC DSN in PARM not implemented | src/luaexec.c | Use LUAIN DD until DSN parsing is implemented | validation |
| LUZ30042 | LUAEXEC load failed: %s | src/luaexec.c | Check LUAIN DD allocation and script syntax | runtime |
| LUZ30043 | LUAEXEC run failed: %s | src/luaexec.c | Inspect script error and LUAPATH configuration | runtime |
| LUZ30044 | LUAEXEC dd register failed | src/luaexec.c | Verify LUAPATH DDNAME allocation | runtime |
| LUZ30045 | tso.* not available in PGM mode | src/tso.c | Run under TSO mode (LUACMD) or enable TSO environment | runtime |
| LUZ30046 | LUAEXEC invalid MODE in PARM | src/luaexec.c | Use MODE=PGM or MODE=TSO | validation |
| LUZ30053 | LUAEXRUN invalid line length | src/luaexec.c | Check CPPL operand length parsing | validation |
| LUZ30054 | LUAEXRUN line pointer is NULL | src/luaexec.c | Verify CPPL operand pointer calculation | validation |
| LUZ30061 | tso_native_env_init failed | src/tso_native.c | Ensure IKJTSOEV is available and CPPL is initialized | diagnostic |
| LUZ30062 | tso_native CPPL unavailable | src/tso_native.c | Ensure LUACMD passes CPPL via TSONCPPL | diagnostic |
| LUZ30063 | tso_native DDNAME allocation failed | src/tso_native.c | Check internal DDNAME generator and outdd buffer | diagnostic |
| LUZ30064 | tso_native work buffer allocation failed | src/tso_native.c | Check 31-bit storage availability | diagnostic |
| LUZ30065 | tso_native TSOCMD failed (dair_rc/cat_rc) | src/tso_native.c | Check DAIR parms, APF, and DDNAME constraints | diagnostic |
| LUZ30066 | tso_native TSOEFTR failed (rc/reason/abend) | src/tso_native.c | Check TSOEFTR call and TSO command status | diagnostic |
| LUZ30067 | tso_native TSOCMD rc=%d | src/tso_native.c | Check TSOCMD parameter block validation | diagnostic |
| LUZ30068 | tso_native TSOCMD dbg parms=%08X cppl=%08X cmd=%08X outdd=%08X dair=%08X work=%08X | src/tso_native.c | Inspect TSOCMD debug snapshot (parameter block, CPPL, CMD ptr, DDNAME, DAIR ptr, work ptr) | diagnostic |
| LUZ30069 | tso_native TSOCMD r1=%08X parms=%08X match=%d | src/tso_native.c | Compare incoming R1 with parameter block address (OS PLIST vs direct) | diagnostic |
| LUZ30070 | ITLUACMD ok LUAZ_MODE=TSO args ok | tests/integration/lua/ITLUACMD.lua | None | diagnostic |
| LUZ30071 | ITLUACMD validation failed: %s | tests/integration/lua/ITLUACMD.lua | Run via LUACMD under IKJEFT01 and ensure MODE=TSO and operands are preserved | validation |
| LUZ30090 | ITLUAINFB ok LUAZ_MODE=TSO args ok | jcl/IT_LUAIN_FB80.jcl | None | diagnostic |
| LUZ30091 | ITLUAINFB fail %s | jcl/IT_LUAIN_FB80.jcl | Run via LUACMD under IKJEFT01 and ensure LUAIN is FB80 in-stream data | validation |
| LUZ30060 | LUAZ_MODE debug output | tests/integration/lua/ITTSO.lua | None | diagnostic |
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
