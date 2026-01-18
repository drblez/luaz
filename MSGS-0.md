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
