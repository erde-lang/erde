# TODO

# 0.4-2

- separate parser from compiler
- readd `try...catch`, fix previous implementation of nested `return`!
- replace source maps with placing compiled code on same line
- add autocompletions + command to install / uninstall autocompletions

# 1.0-1

- rewrite erde in erde

# Future Plans

- pretty compile
  - will lose sourcemaps
  - nice for hand debugging / distribution
- formatter
- converter (lua -> erde)
- debug mode for `erde.load`
  - wrap anonymous functions with pcalls to sourcemap (since may be run in lua context)
  - wrap imports to provide error if try to destructure nontable

# Possible Language Features (needs further discussion)
- Allow strings as index chain bases
  - ex) `"hello %s":format(name)`
