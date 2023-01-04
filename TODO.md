# TODO

# 0.3-3

- fix: erde_history in repl
- fix: varargs outside function throws internal error
- fix: destructuring non table module error
- support column errors lines (also in source maps!)

# 1.0-1

- rewrite erde in erde

# Future Plans

- separate parser from compiler (for other subprojects)
- formatter
- pretty compile
  - will lose sourcemaps
  - nice for hand debugging
- emit sourcemaps
  - need to make more compact first
- debug mode for `erde.load`
  - wrap anonymous functions with pcalls to sourcemap (since may be run in lua context)

# Possible Language Features (needs further discussion)
- Allow strings as index chain bases
  - ex) `"hello %s":format(name)`
