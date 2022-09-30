# TODO

# 0.3-2

- add CLI REPL
- add tests for external parens (to throw away unused values)
  - ex) `return (myfunc())`
- improve error messages (mimic lua)

# 1.0-1

- rewrite erde in erde

# 1.0-2

- formatter

# Possible Future Subprojects

- checker
  - check correct syntax
  - undeclared variables
  - etc (see https://github.com/lunarmodules/luacheck)

# Possible Language Features (needs further discussion)
- Allow strings / tables as index chain bases
  - ex) `"hello %s":format(name)`
- Allow arbitrary first parameter injection syntax
  - ex) `mytable::filter(() -> true)` == `filter(mytable, () -> true)`
- Allow assignments in branches (if, elseif, with)
  - ex) `if myvar = someFunc() { ... }` => `do { local myvar = someFunc() if myvar { ... } }`
