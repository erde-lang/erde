# TODO

# 0.4-2

- allow binary numbers when targeting luajit
- add autocompletions + command to install / uninstall autocompletions
- separate parser from compiler
- make source maps more compact
- support column errors lines (also in source maps!)

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
