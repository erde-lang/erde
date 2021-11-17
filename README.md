# Erde

## TODO

- optimistic errors (try to guess the attempted rule)
- Source maps?
- Formatter
- Declaration files?
- Optimizations?

## Intended Proposals

- spread operator
  - `local x = { ...y }`
  - `myfunc(1, 4, ...x, 3, ...y, 6)`
- Processors
  - validate continue / break
  - validate variable scopes?
- module (export!)
  - must happen at top level
  - use processor to register module parts
- keywords
  - kpairs

## Uncertain Proposals (need community input)

- decorators
