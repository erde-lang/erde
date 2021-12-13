# Erde

## TODO

- Formatter
- Source maps?
- Declaration files?

## Intended Proposals

- refactor + improved tests + improved error msgs
  - allow optional chaining in declarations
  - optimize Space calls (too many)
  - flatten AST (ex. compile Numbers directly)
- stdlib
  - special stdlib call syntax: `compileParts >> !join`
  - inline definitions

## Uncertain Proposals (need community input)

- decorators
- nested break
- `scope` keyword (allow scoped blocks)
    - ex) `local x = scope { return 4 }`
    - useful for grouping logical computations
