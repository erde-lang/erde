# TODO

# 0.4-2

- transpile numbers for different versions
- debug compiling for `erde.load` and `erde` cli
  - wrap function call bodies in pcall to rewrite errors.
  - wrap destructures in case trying to destructure non table
- Allow strings as index chain bases
  - ex) `"hello %s":format(name)`
- add columns to source maps
- add autocompletions + command to install / uninstall autocompletions

# 1.0-1

- rewrite erde in erde

# Future Plans

- formatter (unopiniated!)
  - auto indent
  - fix spaces
  - delete trailing whitespace / newlines
  - infer trailing commas
  - infer single vs multi line lists
- converter (lua -> erde)

# Possible Language Features (needs further discussion)
- function decorators (too non-lua-esque?)
- opt chaining
  - avoid iife when possible (be careful of conditional expressions)
