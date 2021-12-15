# TODO

- refactor + improved tests
  - shorthand for `if not ctx:branchChar('=') then ctx:throwExpected('=') end`
  - flatten AST (ex. compile Numbers directly)
  - refactor module compilation. Need to handle local refs:
    - `module myvar = 3`
    - `print(myvar)`
  - allow optional chaining in declarations
- stdlib
  - special stdlib call syntax: `compileParts >> !join`
  - inline definitions
- improved error messages (add pcalls, Rule.diagnose)

# Long Term TODO

- Formatter
- release v0.1.0
- rewrite erde in erde
- Source maps
- remove closure compilations (ternary, null coalescence, optchain, etc).
  - analyze usage and inject code (in particular, transform logical operations
    into if constructs (ex. `local a = b or c ?? d`
  - NOTE: cannot simply use functions w/ params (need conditional execution)

# Uncertain Proposals (need community input)

- macros
- decorators
- nested break
- `scope` keyword (allow scoped blocks)
    - ex) `local x = scope { return 4 }`
    - useful for grouping logical computations