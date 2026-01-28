# Lua VM: функции как вызываются из Lua

Этот список извлечён из `lua-vm/src` и показывает имена функций в Lua-коде.

Примечания:
- `global` — это функции в глобальном окружении (`_G`).
- `file:` — методы файлового дескриптора (объект, возвращаемый `io.open`).
- `string.*` также доступны как методы строк (`"abc":len()` и т.п.).

## _G (глобальные функции)

Источник: `lua-vm/src/lbaselib.c` (base_funcs), `lua-vm/src/loadlib.c` (ll_funcs)

- `assert`
- `collectgarbage`
- `dofile`
- `error`
- `getmetatable`
- `ipairs`
- `load`
- `loadfile`
- `next`
- `pairs`
- `pcall`
- `print`
- `rawequal`
- `rawget`
- `rawlen`
- `rawset`
- `require`
- `select`
- `setmetatable`
- `tonumber`
- `tostring`
- `type`
- `warn`
- `xpcall`

## package.*

Источник: `lua-vm/src/loadlib.c` (pk_funcs)

- `package.loadlib`
- `package.searchpath`

## coroutine.*

Источник: `lua-vm/src/lcorolib.c` (co_funcs)

- `coroutine.close`
- `coroutine.create`
- `coroutine.isyieldable`
- `coroutine.resume`
- `coroutine.running`
- `coroutine.status`
- `coroutine.wrap`
- `coroutine.yield`

## debug.*

Источник: `lua-vm/src/ldblib.c` (dblib)

- `debug.debug`
- `debug.gethook`
- `debug.getinfo`
- `debug.getlocal`
- `debug.getmetatable`
- `debug.getregistry`
- `debug.getupvalue`
- `debug.getuservalue`
- `debug.sethook`
- `debug.setlocal`
- `debug.setmetatable`
- `debug.setupvalue`
- `debug.setuservalue`
- `debug.traceback`
- `debug.upvalueid`
- `debug.upvaluejoin`

## io.*

Источник: `lua-vm/src/liolib.c` (iolib)

- `io.close`
- `io.flush`
- `io.input`
- `io.lines`
- `io.open`
- `io.output`
- `io.popen`
- `io.read`
- `io.tmpfile`
- `io.type`
- `io.write`

## file: методы файлового дескриптора

Источник: `lua-vm/src/liolib.c` (meth)

- `file:close`
- `file:flush`
- `file:lines`
- `file:read`
- `file:seek`
- `file:setvbuf`
- `file:write`

## math.*

Источник: `lua-vm/src/lmathlib.c` (mathlib)

- `math.abs`
- `math.acos`
- `math.asin`
- `math.atan`
- `math.atan2`
- `math.ceil`
- `math.cos`
- `math.cosh`
- `math.deg`
- `math.exp`
- `math.floor`
- `math.fmod`
- `math.frexp`
- `math.ldexp`
- `math.log`
- `math.log10`
- `math.max`
- `math.min`
- `math.modf`
- `math.pow`
- `math.rad`
- `math.sin`
- `math.sinh`
- `math.sqrt`
- `math.tan`
- `math.tanh`
- `math.tointeger`
- `math.type`
- `math.ult`

## os.*

Источник: `lua-vm/src/loslib.c` (syslib)

- `os.clock`
- `os.date`
- `os.difftime`
- `os.execute`
- `os.exit`
- `os.getenv`
- `os.remove`
- `os.rename`
- `os.setlocale`
- `os.time`
- `os.tmpname`

## string.*

Источник: `lua-vm/src/lstrlib.c` (strlib)

- `string.byte`
- `string.char`
- `string.dump`
- `string.find`
- `string.format`
- `string.gmatch`
- `string.gsub`
- `string.len`
- `string.lower`
- `string.match`
- `string.pack`
- `string.packsize`
- `string.rep`
- `string.reverse`
- `string.sub`
- `string.unpack`
- `string.upper`

## table.*

Источник: `lua-vm/src/ltablib.c` (tab_funcs)

- `table.concat`
- `table.create`
- `table.insert`
- `table.move`
- `table.pack`
- `table.remove`
- `table.sort`
- `table.unpack`

## utf8.*

Источник: `lua-vm/src/lutf8lib.c` (funcs)

- `utf8.char`
- `utf8.codepoint`
- `utf8.codes`
- `utf8.len`
- `utf8.offset`

