# name

## Syntax

### Variables

```
local x = 1
const y = {}
```

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

#### Optional Parentheses

Parentheses are optional if there is only 1 parameter. This holds for both
declaration AND invocation:

```
const MyFunction = x => 2 * x

print(MyFunction 2)
```

Exception: Single parameter in declaration is either optional or variadic.

```
// bad: no optional
const MyFunction = x = 2 => 2 * x

// bad: no variadic
const MyFunction = ...x => 2 * x
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
