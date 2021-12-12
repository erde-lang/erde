# Erde

## TODO

- Formatter
- Source maps?
- Declaration files?

## Intended Proposals

- stdlib?
  - special stdlib call syntax: `compileParts >> !join`
- refactor + improved tests + improved error msgs
  - throw number parse error based on version
  - throw error on `return` w/ `module`
  - allow optional chaining in declarations
  - optimize Space calls (too many)
  - flatten AST (ex. compile Numbers directly)

## Uncertain Proposals (need community input)

- decorators
- nested break
- `scope` keyword (allow scoped blocks)
    - ex) `local x = scope { return 4 }`
    - useful for grouping logical computations
