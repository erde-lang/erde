# Erde

## TODO

- optimistic errors (try to guess the attempted rule)
- Source maps?
- Formatter
- Declaration files?
- Optimizations?

## Intended Proposals

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
