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
