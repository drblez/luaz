# LUZ Message Catalog (0xxxx)

| Code | Message | Context | User Action | Notes |
|------|---------|---------|-------------|-------|
| LUZ00000 | Reserved for message catalog initialization | global | None | Keep for tooling/tests |
| LUZ00002 | LUAPATH UT OK | tests | None | unit test |
| LUZ00003 | LUAPATH UT failed | tests | Inspect UT_LUAPATH job output and LUAPATH dataset | unit test |
| LUZ00004 | DS UT OK | tests | None | unit test |
| LUZ00005 | DS UT failed | tests | Inspect UT_DSOPEN job output and DDNAME allocations | unit test |
| LUZ00006 | DS UT open failed | tests | Verify DDNAME allocation and dataset existence | unit test |
| LUZ00007 | DS UT read failed | tests | Verify dataset content and RECFM/LRECL | unit test |
| LUZ00008 | DS UT empty read | tests | Ensure dataset has records | unit test |
| LUZ00009 | loadfile UT OK | tests | None | unit test |
| LUZ00010 | loadfile UT failed | tests | Inspect UT_LOADFILE job output and LUAPATH dataset | unit test |
| LUZ00011 | TSO UT OK | tests | None | unit test |
| LUZ00012 | TSO UT failed | tests | Inspect UT_TSO job output and module status | unit test |
| LUZ00013 | IRXEXEC UT OK | tests | None | unit test |
| LUZ00014 | IRXEXEC UT failed | tests | Inspect UT_IRXEXEC job output and IRXEXEC linkage | unit test |
| LUZ00015 | tso_call_rexx enter dd=%s member=%s mode=%s outdd=%s | tests | Capture UT_TSO output for IRXEXEC parameter tracing | debug |
| LUZ00016 | tso_call_rexx irx_rc=%d rexx_rc=%d | tests | Capture UT_TSO output for IRXEXEC result tracing | debug |
| LUZ00017 | TSOUT start | tests | If missing, main did not start; inspect SYSUDUMP | debug |
| LUZ00018 | TSOX start | tests | If missing, TSOLUT did not start | debug |
| LUZ00019 | TSOX failed: %s | tests | Inspect UT_TSOX output and LUTSO exec | debug |
| LUZ00020 | Lua IT OK | tests | None | integration test |
| LUZ00021 | Lua IT failed | tests | Inspect IT_TSO job output and test script | integration test |
| LUZ00022 | TSNUT start | tests | If missing, native TSO UT did not start | unit test |
| LUZ00023 | TSNUT failed rc=%d reason=%d abend=%d dair_rc=%d cat_rc=%d | tests | Inspect UT_TSN output and DAIR/IKJEFTSR status | unit test |
| LUZ00024 | TSNENV start | tests | If missing, native TSO env UT did not start | unit test |
| LUZ00025 | TSNENV failed rc=%d | tests | Inspect UT_TSNENV output and IKJTSOEV status | unit test |
| LUZ00026 | TSOAUTH start | tests | If missing, authorized TSO stub did not start | unit test |
| LUZ00027 | TSOAUTH failed rc=%d | tests | Verify AUTHPGM/AUTHTSF and APF authorization, then rerun UT_TSOAUTH | unit test |
| LUZ00028 | TSOAUTH alloc failed | tests | Ensure sufficient region and storage availability, then rerun UT_TSOAUTH | unit test |
| LUZ00029 | TSOAUTH rc=%d reason=%d abend=%d | tests | Inspect UT_TSOAUTH output and IKJEFTSR reason/abend codes | unit test |
| LUZ00030 | TSOAF start | tests | If missing, alloc/free test did not start | unit test |
| LUZ00031 | TSOAF IKJTSOEV rc=%d rsn=%d abend=%d cppl=%p | tests | Ensure TMP is active and IKJTSOEV returns RC=0/8/24 | unit test |
| LUZ00032 | TSOAF tsodalc dd=%s dair_rc=%d cat_rc=%d | tests | Check TSODALC inputs and DAIR RCs | unit test |
| LUZ00033 | TSOAF IKJEFTSR svc_rc=%d cmd_rc=%d rsn=%d abend=%d | tests | Check TSO command status and IKJEFTSR reason/abend | unit test |
| LUZ00034 | TSOAF read dd=%s failed | tests | Verify DDNAME allocation and record I/O attributes | unit test |
| LUZ00035 | TSOAF %s | tests | Inspect captured SYSTSPRT lines | unit test |
| LUZ00036 | TSOAF tsodfre dd=%s dair_rc=%d cat_rc=%d | tests | Check TSODFRE inputs and DAIR RCs | unit test |
| LUZ00037 | TSOAF failed | tests | Inspect prior TSOAF diagnostics for failure reason | unit test |
| LUZ00038 | TSOAF log DD open failed | tests | Ensure TSOAFLOG DD is allocated in JCL | unit test |
