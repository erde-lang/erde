# TODO

# 0.3-2

- fix line numbers for ending compile errors
- improve error messages
- add types to all internal errors
  - remove need for backslash in repl. Instead, continue user input if error is EOL error

# 0.3-3

- Use `do` expression as IIFE syntactic sugar

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
- Nested breaks using numbers (-1 for break all)
  - ex) `break 2`, `break -1`
- Allow strings / tables as index chain bases
  - ex) `"hello %s":format(name)`
- Allow assignments in branches (if, elseif, while)
  - ex) `if myvar = someFunc() { ... }` => `do { local myvar = someFunc() if myvar { ... } }`
