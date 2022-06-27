# TODO

# 0.3-1

- Source maps (for runtime errors when using erde.loader)
  - preserve line numbers when compiling
- Add semicolons (like Lua)
- officially readd 5.1+ support
  - support multiple bitwise operator compiles (best effort based on versions)
- throw error if only part of file is parsed
- throw version errors for number forms
- throw version errors for escape valid escape chars
  - https://www.lua.org/manual/5.1/manual.html#2.1
  - https://www.lua.org/manual/5.4/manual.html#3.1
- vastly improve error messages / diagnosis

# 0.4-1

- add CLI REPL

# 1.0-1

- rewrite erde in erde

# Future Goals

- formatter
- linter
  - undeclared variables
  - unitialized variable
  - etc (see https://github.com/lunarmodules/luacheck)
- reverse compiler (compile Lua to Erde)
