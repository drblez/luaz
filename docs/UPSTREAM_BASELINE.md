# Upstream Baseline

- Lua upstream release: 5.5.0
- Location: `third_party/lua/lua-5.5.0/` (ignored in git)
- Source root: `third_party/lua/lua-5.5.0/src/`

Subsystem touchpoints to review for z/OS porting:

- VM/core: `lvm.c`, `ldo.c`, `lgc.c`, `lmem.c`
- Parser/compiler: `llex.c`, `lparser.c`, `lcode.c`
- Libraries: `lbaselib.c`, `liolib.c`, `loslib.c`, `lstrlib.c`, `lmathlib.c`
- Dynamic loading: `loadlib.c`
- Init/bootstrap: `linit.c`, `lua.c`
