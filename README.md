# Erde

## TODO

- Formatter
- Source maps?
- Declaration files?

## Intended Proposals

- keywords / stdlib?
  - stdlib?
    - special stdlib call syntax?
    - `compileParts >> !join`
- refactor + improved tests + improved error msgs
  - only accept function calls in pipes
  - throw number error based on version
  - require global at top level
  - throw error on `return` w/ `module`
  - allow names to start with `_`
  - allow optional chaining in declarations

## Uncertain Proposals (need community input)

- decorators
- nested break
- `scope` keyword (allow scoped blocks)
    - ex) `local x = scope { return 4 }`
    - useful for grouping logical computations
