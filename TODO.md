# TODO

# 0.3-1

- release!
- update / improve documentation

# 0.3-2

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
- linter?
  - undeclared variables
  - unitialized variable
  - etc (see https://github.com/lunarmodules/luacheck)
  - maybe just better as lsp client?

# Needs further discussion
- Allow strings / tables as index chain bases?
  - ex) `"hello %s":format(name)`
- Allow arbitrary first parameter injection syntax
  - ex) `mytable::filter(() -> true)` == `filter(mytable, () -> true)`
