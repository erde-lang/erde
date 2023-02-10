# TODO

# 0.4-2

- replace source maps with placing compiled code on same line
- refactor / cleanup
- fix assigning module to update table value
- transpile numbers for different versions
- require scope keywords for declarations
  - throw error on undeclared variables
  - global variables should be declared at top of file
- add autocompletions + command to install / uninstall autocompletions

# 1.0-1

- rewrite erde in erde

# Future Plans

- formatter
- converter (lua -> erde)
- debug mode for `erde.load`
  - wrap imports to provide error if try to destructure nontable

# Possible Language Features (needs further discussion)
- Allow strings as index chain bases
  - ex) `"hello %s":format(name)`
- function decorators (too non-lua-esque?)
- opt chaining
  - avoid iife when possible (be careful of conditional expressions)
