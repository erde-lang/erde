# TODO

# 0.3-1

- release!

# 0.3-2

- add CLI REPL

# 1.0-1

- rewrite erde in erde

# Possible Future Subprojects

- formatter
- reverse compiler (compile Lua to Erde)
- linter
  - undeclared variables
  - unitialized variable
  - etc (see https://github.com/lunarmodules/luacheck)
- language server

# Possible Language Features (needs further discussion)
- Allow strings / tables as index chain bases
  - ex) `"hello %s":format(name)`
- Allow arbitrary first parameter injection syntax
  - ex) `mytable::filter(() -> true)` == `filter(mytable, () -> true)`
