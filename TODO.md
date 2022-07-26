# TODO

# 0.3-1

- officially readd 5.1+ support
  - support multiple bitwise operator compiles (best effort based on versions)
- throw error if only part of file is parsed
- throw version errors for number forms
- throw version errors for escape valid escape chars
  - https://www.lua.org/manual/5.1/manual.html#2.1
  - https://www.lua.org/manual/5.4/manual.html#3.1
- improve test coverage
  - more compiler tests
  - lua version tests
  - error handling tests
  - erde API tests
- vastly improve error messages / diagnosis
  - include line numbers (use this in `__erde_internal_load_source__`!)
- update / improve documentation

# 0.4-1

- refactor tokenizer (for organization, do not microoptimize)
- add CLI REPL
- documentation
  - tutorial
  - playground

# 1.0-1

- rewrite erde in erde

# Docs

- change to "Differences from lua"
- returns allow parentheses (for multiline returns)
- no semicolons?
- multi binop assignment
- Limitations
  - cannot retain line numbers for compiled code
    - local { x = myexpr() } =
        myreallylongfunctioncall()
    - Error can happen at default assignment in destructure or assignment expr
    - Cannot keep destructure on same line, since it needs to happen after
      assignment and need to also retain line number of `myreallylongfunctioncall`!

# Future Goals

- formatter
- reverse compiler (compile Lua to Erde)
- `::` operator to place arbitrary expressions as first argument?
  - Allows for `mytable::filter(...)::map(...)` -> `map(filter(mytable, ...), ...)`
- linter?
  - undeclared variables
  - unitialized variable
  - etc (see https://github.com/lunarmodules/luacheck)
  - maybe just better as lsp client?
