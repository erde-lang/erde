# Erde

## TODO

- optimistic errors (try to guess the attempted rule)
- Source maps?
- Formatter
- Declaration files?
- Optimizations?

## Intended Proposals

- destructure improvements
  - allow aliases:
    - 'local { a: customname } = { a: 2 } 
  - default to map destructure (most common case)
    - `local { a } = { a = 1 }`
    - revert syntax `:` -> `=` (no longer need `:`)
    - need new number index destructure syntax
    - `local { x, [test, test2] } = a`
    - `local [test, test2] = a`
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
