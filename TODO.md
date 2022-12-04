# TODO

# 0.3-3

- allow args to be passed to interpreter script (like lua, replace `arg` global)
- support column errors lines (also in source maps!)
- Use `eval` expression as IIFE syntactic sugar

# 1.0-1

- rewrite erde in erde

# 1.0-2

- formatter

# Possible Language Features (needs further discussion)
- Allow strings as index chain bases
  - ex) `"hello %s":format(name)`
- Limited walrus operator
  - only allowed in branches (if, elseif, while, until)
  - ex) `if myvar = someFunc() { ... }` => `do { local myvar = someFunc() if myvar { ... } }`
- Nested breaks using numbers (-1 for break all)
  - ex) `break 2`, `break -1`
