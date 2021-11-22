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
  - validate module
- compiling modulo operator (conflicts w/ replacement)
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
- nested break
