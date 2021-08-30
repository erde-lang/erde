# Orbit

## TODO

- assignment operators (+=, -=)
- unary operators

- Optional chaining (dot index, bracket index, function call)
- index declaration (`local a.b = 'test'`, `local a?.b = 'test'`)

- DUE ???
- case statement
- table casting
- Macros
- require global keyword for global vars? (would be awesome, but requires scope tracking...)
- recall keyword? (recall the function of the current scope?)

- DUE ???
- order of operations?
- automated tests
- Error messages

## Long Term TODO

- Syntax highlighting
  - Vim
  - Emacs
  - Vscode
  - Treesitter
- orbit cli
  - target various lua versions
  - luajit bytecode option?
- orbit lib
  - allow mutating `require` (similar to moonscript)
- docs site
- Formatter
- Source maps?

## Syntax

### Strings

Similar to JS

```
local x = `
  this is a
  multiline
  string
`

// interpolation, but without '$'
local greeting = "hello"
local y = `{greeting} world!`

// Can use table length operator:
print(#'this is a string')
```

### Variables

```
local x = 1

// maybe?
const y = {}
```

### Logic flow

#### If else

Similar to go, but uses elseif like lua:

```
if n > 0 {

} elseif n < 0 {

} else {

}

// Maybe inline statements like go?
if x = myfunc(); x > 0 {

}
```

#### For loop

There is no for loop. Instead, use Array constructors + macros:

```
[]{4}::IPairs(() => {

})
```

#### While Loop

There is no while loop. Orbit retains the tail recursiveness of lua, so you may
use recursive functions in place of traditional while loops.

#### Case statement

One of orbits unique features. Similar to a `switch` statement but:

1. case statements can return values
1. No need to use `case` keyword
1. Rather than hard values, expressions are used
1. The cased value is accessible as "$"

```
local test = case myfunc() {
  $ > 4:
    dosomething()
    doanotherthing()
    return 3
  $ < 10:
    return $ + 3
  $ == 10:
  $ == 4:
    return 10
  true:
    return 4
}
```

### Tables

#### Declaring

No semicolon delimiter, use ':' instead of '='.

```
const t = {
  hello: "world",
  cake: "lie",

  31415,
  "test",
}
```

Can use arbitrary strings as indexes:

```
const hello = 'hello'

const t = {
  `{hello}`: world
}
```

#### Destructuring

For now, nested destructuring is not supported, but is strongly considered for
the future. This can become pretty unreadable so want this to be community
driven.

```
const t = {...}

// Number fields
const [a1, a2] = t

// String fields
const { :hello, :cake } = t

// Simultaneous

const [a1, a2], { :hello, :cake } = t
```

Can also null coalesce inside destructure:

```
const { :hello ?? 'world' } = t
```

#### Casting

Can cast to ipairs or kpairs:

```
const t = {
  hello: "world",
  123,
}

// { 123 }
const tarray = t[]

// { hello: "world" }
const tmap = t{:}
```

### Functions

#### Declaration

All functions are arrow functions. Params MUST be wrapped in parentheses.

```
const MyFunction = () => {
  local x = 3

  ...

  return x
}
```

#### Implicit Return

Arrow function have implicit return, like JS:

```
const MyFunction = () => "hello world"

// prints "hello world"
print(MyFunction())
```

#### Optional Params / Varargs

```
const MyFunction = (x = 4)
const MyFunction = (x = 4, ...)
const MyFunction = (x = 4, ...children)
```

### Oddities

#### Ternary

Like JS

```
const x = condition ? true : false
```

#### Null Coalescence

Like JS

```
const x = "hello" ?? "world"
```

#### Optional Chaining

Similar to JS

```
print(a?b?c)
print(a?['b'])
print(a?[0])
```

NOTE: _Replaces_ dot, no dot index required

Can also use while setting:

```
// Does nothing if null
a?b?c = 4
```

#### Array Constructors

The expression `[X]{N}` creates an table of length `N` filled with `X`. If `X`
is a table, it will be **shallow copied**. `X` defaults to nil.

```
// { nil, nil, nil, nil }
const x = []{4}

// {0, 0}
const x = [0]{2}

// { {}, {}, {} }
const x = [{}]{3}
```

#### Macros

- Pairs
- IPairs
- KPairs
- Map
- IMap
- KMap
- Filter
- IFilter
- KFilter
- Reduce
- IReduce
- KReduce
- Meta

```
const t = {
  key: "value",
  456,
}

const str = t[]::Join(" ")

t::[]Pairs(() => {

})
```

## Conventions

- All functions / macros are UpperCamelCase
