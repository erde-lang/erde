# TODO

- refactor tests
- lua love (kaos)
- replace moduleBlock w/ block depth
- formatter (Rule.format)
- repl
- improved error messages (add pcalls, Rule.diagnose)
- CLI
  - `erde format`
  - `erde` REPL

# Long Term TODO

- add real README
- release v0.1.0
- rewrite erde in erde
- Source maps
- remove closure compilations (ternary, null coalescence, optchain, etc).
  - analyze usage and inject code. In particular, transform logical operations into if constructs (ex. `local a = b or c ?? d`)
  - NOTE: cannot simply use functions w/ params (need conditional execution)

# Uncertain Proposals (need community input)

- macros
- decorators
- nested break
- `scope` keyword (allow scoped blocks)
    - ex) `local x = scope { return 4 }`
    - useful for grouping logical computations
