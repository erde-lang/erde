# Erde

## TODO

- optimistic errors (try to guess the attempted rule)
- Source maps?
- Formatter
- Declaration files?
- Optimizations?

## Intended Proposals

- destructure improvements
  - revert syntax `:` -> `=` (no longer need `:`)
    - `local { a } = { a = 1 }`
  - allow aliases:
    - `local { a: customname } = { a = 2 }`
    - `local [test: mytest, test2] = a`
- new pipe syntax
  - `fields >> !map(x -> 2 * x)`
  - `('hello', 'world') >> !map(x -> 2 * x)`
- Processors
  - validate continue / break
  - validate variable scopes?
    - probably cannot, many things use environments...
      - nvim
      - love
      - etc.
- module (export!)
  - must happen at top level
  - use processor to register module parts
- keywords / stdlib?
  - kpairs
  - stdlib?
    - special stdlib call syntax?
    - `compileParts >> !join`

## Uncertain Proposals (need community input)

- decorators
