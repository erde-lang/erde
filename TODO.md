# TODO

# 0.2-1

- simplify / microoptimize parser
- change ruleName -> tag
- remove variants in favor of separate tags
  - ex) `tag = NumericFor`, `tag = GenericFor`
  - ex) DoBlock -> `isExpr`
- throw error if only part of file is parsed
- throw errors for undeclared variables (precompile)

# 0.3-1

- officially readd 5.1+ support
  - support multiple bitwise operator compiles (best effort based on versions)
- Source maps (for runtime errors when using erde.loader)
  - preserve line numbers when compiling
- Avoid closure creation (slow, cannot be JITed)
  - ex) compile assignment / declaration into if statements
- allow optimizations depending on compilation target
  - ex) exploit goto when available

# 0.4-1

- add CLI REPL

# 1.0-1

- rewrite erde in erde

# Uncertain Proposals (need community input)

- macros
- decorators (like python / js)
- if assignments (`if x = myfunc() { ... }`)
- Allow all blocks as expressions (`local x = if x { return y }`)
- nested break
