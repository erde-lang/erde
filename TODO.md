# TODO

# 0.3-2

- add watch mode (linotify w/ lfs + polling backup)
- remove argparse dependency (hand craft)
- improve error messages
- add types to all internal errors
  - remove need for backslash in repl. Instead, continue user input if error is EOL error

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
