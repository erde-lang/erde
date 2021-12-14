# TODO

- refactor + improved tests + improved error msgs
  - refactor module compilation. Need to handle local refs:
    - `module myvar = 3`
    - `print(myvar)`
  - allow optional chaining in declarations
  - flatten AST (ex. compile Numbers directly)
  - better Switch handing
    - provide Rule.test method instead of waiting for errors? Not always possible
    - since Params with no defaults / varargs looks like list of expr
- stdlib
  - special stdlib call syntax: `compileParts >> !join`
  - inline definitions

# Long Term TODO

- Formatter
- release v0.1.0
- rewrite erde in erde
- improved error messages (use `try catch`, add Rule.diagnose)
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
