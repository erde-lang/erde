# Kale

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
```

#### For loop

There is no for loop. Instead, use Array constructors + macros:

```
[]{4}::Ipairs () => {

}
```

#### While Loop

TODO

### Tables

#### Declaring

Same as lua

```
const t = {
  hello: "world",
  cake: "lie",

  31415,
  "test",
}
```

#### Destructuring

```
const t = {...}

// Number fields
const [a1, a2] = t

// String fields
const { hello, cake } = t

// Simultaneous

const [a1, a2], { hello, cake } = t
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
const tmap = t{}
```

### Functions

#### Declaration

All functions are arrow functions.

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

#### Optional Params

```
const MyFunction = (x = 4)
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

const str = t[]::Join " "

t::[]Pairs(() => {

})
  ::
```

## Conventions

- All functions / macros are UpperCamelCase
