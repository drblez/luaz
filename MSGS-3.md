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
| LUZ30082 | tso.cmd alloc failed rc=%d dair=%d cat=%d da34_darc=%d da34_flg=%d r15_34=%d r15_08=%d dslen=%d ds_hex=%s dd=%s dd_hex=%s | src/tso.c | Verify DAIR availability under TMP, DAIR X'34' outputs, and DDNAME diagnostics | runtime |
| LUZ30083 | tso.cmd free failed rc=%d dair=%d cat=%d | src/tso.c | Ensure OUTDD was allocated via DAIR and TSODFRE is available | runtime |
| LUZ30084 | tso.cmd missing CPPL for STACK output | src/tso.c | Run under LUACMD or ensure IKJTSOEV returns a CPPL address | runtime |
| LUZ30085 | tso.cmd stack outdd failed rc=%d open_errno=%d open_errno2=%d dair=%d cat=%d flg=%d da34_darc=%d da34_flg=%d r15_34=%d r15_08=%d dslen=%d ds_hex=%s dd=%s dd_hex=%s | src/tso.c | Verify STACK OUTDD parameters, DAIR X'34'/X'08' outputs, and OPEN diagnostics | runtime |
| LUZ30086 | tso.cmd stack close failed rc=%d | src/tso.c | Ensure STACK CLOSE is valid and DCB state is consistent | runtime |
| LUZ30087 | tso.cmd stack delete failed rc=%d | src/tso.c | Ensure STACK DELETE=TOP is valid for the current I/O stack | runtime |
| LUZ30088 | tso.cmd free outdd failed rc=%d | src/tso.c | Ensure TSO FREE DD(TSOOUT) is available and LUTSO ran successfully | runtime |
| LUZ30089 | LUAEXEC LUAOUT open failed errno=%d | src/luaexec.c | Allocate LUAOUT DDNAME and ensure it is writable; review errno for details | runtime |
| LUZ30092 | LUAEXEC LUAOUT io.output failed: %s | src/luaexec.c | Verify Lua io library initialization and LUAOUT handle setup | runtime |
| LUZ30093 | LUACFG line too long line=%d | src/policy.c | Shorten LUACFG line or split values | runtime |
| LUZ30094 | LUACFG invalid line=%d | src/policy.c | Use `key = value` format in LUACFG | runtime |
| LUZ30095 | LUACFG unknown key=%s line=%d | src/policy.c | Remove the key or add support in LUACFG parser | runtime |
| LUZ30096 | LUACFG invalid value key=%s line=%d | src/policy.c | Fix value format for the specified key | runtime |
| LUZ30097 | LUACFG value too long key=%s line=%d | src/policy.c | Shorten the value to fit limits | runtime |
| LUZ30098 | LUACFG duplicate key=%s | src/policy.c | Remove duplicate entries or keep a single key | runtime |
| LUZ30099 | tso.cmd blocked by policy allowlist verb=%s | src/tso.c | Add command to allowlist or change allow mode | runtime |
| LUZ30100 | tso.cmd blocked by policy denylist verb=%s | src/tso.c | Remove command from denylist or change allow mode | runtime |
| LUZ30033 | tso.alloc failed (native rc in message) | src/tso.c | Check native DAIR path and ALLOC spec | runtime |
| LUZ30034 | tso.free failed (native rc in message) | src/tso.c | Ensure DDNAME is allocated and native DAIR path works | runtime |
| LUZ30035 | tso.msg failed (irx_rc/rexx_rc in message) | src/tso.c | Ensure IKJTSOEV init and message string are valid | runtime |
| LUZ30036 | LUTSO invalid mode | rexx/LUTSO.rexx | Use supported modes CMD/ALLOC/FREE/MSG | validation |
| LUZ30040 | LUAEXEC init failed | src/luaexec.c | Verify LE runtime availability and memory | runtime |
| LUZ30041 | LUAEXEC DSN in PARM not implemented | src/luaexec.c | Use LUAIN DD until DSN parsing is implemented | validation |
| LUZ30042 | LUAEXEC load failed: %s | src/luaexec.c | Check LUAIN DD allocation and script syntax | runtime |
| LUZ30043 | LUAEXEC run failed: %s | src/luaexec.c | Inspect script error and LUAPATH configuration | runtime |
| LUZ30044 | LUAEXEC dd register failed | src/luaexec.c | Verify LUAPATH DDNAME allocation | runtime |
| LUZ30045 | tso.* not available in PGM mode | src/tso.c | Run under TSO mode (LUACMD) or enable TSO environment | runtime |
| LUZ30047 | tso.cmd TSO environment unavailable | src/tso.c | Ensure IKJTSOEV returns rc=0/8/24 under TMP | runtime |
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
| LUZ30072 | LUAEXRUN dbg line=%08X len=%d buf=%08X argv=%08X | src/luaexec.c | Compare printed addresses with SNAPX dump to validate ASM->C parameter passing | diagnostic |
| LUZ30073 | LUAEXRUN parse line len=%d text='%.*s' | src/luaexec.c | Print raw LUACMD line content before tokenization to verify MODE= token | diagnostic |
| LUZ30074 | TSONCPPL called cppl=%p | src/tso_native.c | Verify TSONCPPL invocation and CPPL pointer passed from LUACMD | diagnostic |
| LUZ30075 | IKJTSOEV rc=%d reason=%d abend=%d cppl=%p | src/tso_native.c | Validate IKJTSOEV outcome and CPPL pointer returned in TSO mode | diagnostic |
| LUZ30076 | TSONCPPL deref cppl=%p g_env_cppl=%p | src/tso_native.c | Check whether the CPPL cell is populated and cached correctly | diagnostic |
| LUZ30077 | LE abend msg=%d fac=%.3s c1=%d c2=%d case=%d sev=%d ctrl=%d isi=%d abend=%08X reason=%08X | src/luaexec.c | Use the abend/reason fields to look up LE runtime messages or compare with SYSUDUMP | diagnostic |
| LUZ30078 | CEEHDLR failed msgno=%d | src/luaexec.c | Verify LE runtime availability and handler registration | diagnostic |
| LUZ30079 | TSOCMD parms cppl=%p cmd=%p cmd_len=%d outdd=%p reason=%p abend=%p dair=%p cat=%p work=%p | src/tso_native.c | Verify TSOCMD parameter block contents before the ASM call | diagnostic |
| LUZ30080 | TSOCMD %s %02X... | src/tso_native.c | Inspect TSOCMD command/outdd bytes (hex) | diagnostic |
| LUZ30081 | IKJEFTSI RC=00000000 ERR=00000000 ABEND=00000000 RSN=00000000 | src/tsocmd.asm | Check IKJEFTSI return/error/abend/reason in SYSTSPRT before IKJEFTSR | diagnostic |
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
| LUZ30018 | policy get failed | src/policy.c | Check LUACFG content and key names | runtime |
| LUZ30019 | clock backend not implemented | src/time.c | Build without `LUAZ_TIME_ZOS` or implement time hooks | stub |
| LUZ30020 | LUAMAP lookup not implemented | src/path.c | Implement LUAPATH lookup hooks | stub |
| LUZ30021 | LUAPATH load not implemented | src/path.c | Implement LUAPATH loader hooks | stub |
| LUZ30022 | date formatting not implemented | src/time.c | Build without `LUAZ_TIME_ZOS` or implement time hooks | stub |
| LUZ30023 | time computation not implemented | src/time.c | Build without `LUAZ_TIME_ZOS` or implement time hooks | stub |
| LUZ30103 | IKJTSOEV rc=%d rsn=%d ec=%d | src/tso_c_example.c | Ensure TMP (IKJEFT01) and SYSTSIN/SYSTSPRT are allocated and closed | runtime |
| LUZ30104 | IKJEFTSR svc_rc=%d cmd_rc=%d rsn=%d abend=%d | src/tso_c_example.c | Check TSO command status and reason codes; verify TSO environment init | runtime |
| LUZ30105 | fopen output dd=%s failed | src/tso_c_example.c | Verify SYSTSPRT DDNAME allocation and dataset access in JCL | runtime |
| LUZ30110 | TSO output line | src/tso_c_example.c | None | emitted |
