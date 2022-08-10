local compile = require('erde.compile')

--
-- TODO: Add separate section for non rule compiles
-- Ex) Terminals, keyword errors, etc.
--

-- -----------------------------------------------------------------------------
-- Partials
-- -----------------------------------------------------------------------------

describe('params #5.1+', function()
  spec('basic', function()
    assert.run(3, [[
      local function test(a, b) {
        return a + b
      }
      return test(1, 2)
    ]])
  end)

  spec('optional', function()
    assert.run(2, [[
      local function test(a = 2) {
        return a
      }
      return test()
    ]])
  end)

  spec('varargs', function()
    assert.run('hello.world', [[
      local function test(...) {
        return table.concat({ ... }, '.')
      }
      return test('hello', 'world')
    ]])
    assert.run('hello.world', [[
      local function test(...args) {
        return table.concat(args, '.')
      }
      return test('hello', 'world')
    ]])
  end)

  spec('destructure', function()
    assert.run(3, [[
      local function test({ a }, b) {
        return a + b
      }

      local x = { a = 1 }
      return test(x, 2)
    ]])
  end)
end)

-- -----------------------------------------------------------------------------
-- Expressions
-- -----------------------------------------------------------------------------

describe('arrow function #5.1+', function()
  spec('params', function()
    assert.run(1, [[
      local a = (x) -> x
      return a(1)
    ]])
    assert.run(3, [[
      local a = (x, y = 2) -> x + y
      return a(1)
    ]])
    assert.run(3, [[
      local a = (x = 3, y) -> x + y
      return a(1, 2)
    ]])
    assert.run({ 1, 2 }, [[
      local a = (...) -> ({ ... })
      return a(1, 2)
    ]])
    assert.run({ 2, 3 }, [[
      local a = (x, ...) -> ({ ... }) 
      return a(1, 2, 3)
    ]])
    assert.run({ 1, 2 }, [[
      local a = (...x) -> x
      return a(1, 2)
    ]])
    assert.run({ 2, 3 }, [[
      local a = (x, ...y) -> y
      return a(1, 2, 3)
    ]])
    assert.run({ 1, 2, { 3, 4 } }, [[
      local a = (x, y = 2, ...) -> ({ x, y, { ... } })
      return a(1, 2, 3, 4)
    ]])
    assert.run({ 1, 2, { 3, 4 } }, [[
      local a = (x, y = 2, ...z) -> ({ x, y, z })
      return a(1, 2, 3, 4)
    ]])
    assert.run(2, [[
      local a = x -> x + 1
      return a(1)
    ]])
    assert.run(2, [[
      local a = [ x ] -> x + 1
      return a({ 1 })
    ]])
    assert.run(2, [[
      local a = { x } -> x + 1
      return a({ x = 1 })
    ]])
    assert.has_error(function()
      compile('local a = x = 2 -> x')
    end)
    assert.has_error(function()
      compile('local a = x -> { x }')
    end)
  end)

  spec('implicit return', function()
    assert.run(1, [[
      local a = () -> 1
      return a()
    ]])
    assert.run(1, [[
      local a = (x) -> x
      return a(1)
    ]])
    assert.run(3, [[
      local a = (x, y) -> x + y
      return a(1, 2)
    ]])
    assert.run({ 1, 2 }, [[
      local a = (x, y) -> ({ x, y })
      return a(1, 2)
    ]])
    assert.run(3, [[
      local a = () -> (1, 2)
      local b, c = a()
      return b + c
    ]])
  end)

  spec('skinny', function()
    assert.eval('function', 'type(() -> {})')
    assert.run(1, [[
      local a = () -> { return 1 }
      return a()
    ]])
    assert.run(1, [[
      local a = x -> { return x }
      return a(1)
    ]])
  end)

  spec('fat', function()
    assert.eval('function', 'type(() => {})')
    assert.run(1, [[
      local a = { b = 1 }
      a.c = () => { return self.b }
      return a:c()
    ]])
    assert.run(3, [[
      local a = { b = 1 }
      a.c = x => { return self.b + x }
      return a:c(2)
    ]])
  end)

  spec('iife', function()
    assert.eval(1, '(() -> { return 1 })()')
    assert.eval(1, '(() -> 1)()')
  end)
end)

describe('index chain #5.1+', function()
  spec('dot', function()
    assert.eval(1, '({ x = 1 }).x')
    assert.run(1, [[
      local a = { b = 1 }
      return a.b
    ]])
  end)

  spec('bracket', function()
    assert.eval(2, '({ 2 })[1]')
    assert.run(1, [[
      local a = { [5] = 1 }
      return a[2 + 3]
    ]])
  end)

  spec('function call', function()
    assert.run(3, [[
      local a = (x, y) -> x + y
      return a(1, 2)
    ]])
  end)

  spec('method call', function()
    assert.run(3, [[
      local a = {
        b = (self, x) -> self.c + x,
        c = 1,
      }
      return a:b(2)
    ]])
    assert.has_error(function()
      compile('a:b')
    end)
  end)

  spec('chain', function()
    assert.run(2, [[
      local a = { b = { 2 } }
      return a.b[1]
    ]])
    assert.run(2, [[
      local a = { { b = 2 } }
      return a[1].b
    ]])
  end)
end)

describe('strings #5.1+', function()
  spec('single quote', function()
    assert.eval('', "''")
    assert.eval('hello', "'hello'")
    assert.eval('hello\nworld', "'hello\\nworld'")
    assert.eval('\\', "'\\\\'")
  end)

  spec('double quote', function()
    assert.eval('', '""')
    assert.eval('hello', '"hello"')
    assert.eval('hello\nworld', '"hello\\nworld"')
    assert.eval('\\', '"\\\\"')
  end)

  spec('long', function()
    assert.eval('hello world', '[[hello world]]')
    assert.eval(' hello\nworld', '[[ hello\nworld]]')
    assert.eval('a{bc}d', '[[a\\{bc}d]]')
    assert.eval('a[[b', '[=[a[[b]=]')
  end)

  spec('interpolation', function()
    assert.eval('hello {1 + 2}', "'hello {1 + 2}'")
    assert.eval('hello 3', '"hello {1 + 2}"')
    assert.eval('hello 3', '[[hello {1 + 2}]]')
  end)
end)

spec('tables #5.1+', function()
  assert.eval({ 10 }, '{ 10 }')
  assert.eval({ x = 2 }, '{ x = 2 }')
  assert.eval({ [3] = 1 }, '{ [1 + 2] = 1 }')
  assert.eval({ x = { y = 1 } }, '{ x = { y = 1 } }')
end)

describe('unop', function()
  spec('#5.1+', function()
    assert.eval(-6, '2 * -3')
    assert.eval(-6, '-2 * 3')
    assert.eval(-8, '-2 ^ 3')
  end)
  spec('#jit #5.1 #5.2 #5.3+', function()
    assert.eval(6, '4 | 2')
    assert.eval(5, '6 ~ 3')
    assert.eval(2, '6 & 3')
    assert.eval(2, '1 << 1')
    assert.eval(1, '2 >> 1')
  end)
end)

describe('binop #5.1+', function()
  spec('left associative', function()
    assert.eval(5, '1 * 2 + 3')
    assert.eval(7, '1 + 2 * 3')
    assert.eval(11, '1 + 2 * 3 + 4')
  end)

  spec('right associative', function()
    assert.eval(512, '2 ^ 3 ^ 2')
    assert.eval(7, '2 ^ 2 + 3')
  end)

  spec('parens', function()
    assert.eval(25, '5 * (2 + 3)')
  end)
end)

-- -----------------------------------------------------------------------------
-- Statements
-- -----------------------------------------------------------------------------

describe('Assignment #5.1+', function()
  spec('name assignment', function()
    assert.run(1, [[
      local a
      a = 1
      return a
    ]])
  end)

  spec('optchain assignment', function()
    assert.run(1, [[
      local a = {}
      a.b = 1
      return a.b
    ]])
  end)

  spec('multiple name assignment', function()
    assert.run(3, [[
      local a, b
      a, b = 1, 2
      return a + b
    ]])
  end)

  spec('multiple optchain assignment', function()
    assert.run(3, [[
      local a, b = {}, {}
      a.c, b.d = 1, 2
      return a.c + b.d
    ]])
  end)

  spec('binop assignment', function()
    assert.run(3, [[
      local a = 1
      a += 2
      return a
    ]])
    assert.run(8, [[
      local a, b = 1, 2
      a, b += 2, 3
      return a + b
    ]])
  end)
end)

describe('Break #5.1+', function()
  spec('break', function()
    assert.run(6, [[
      local x = 0
      while x < 10 {
        x += 2
        if x > 4 {
          break
        }
      }
      return x
    ]])
  end)
end)

describe('Continue #5.1+', function()
  spec('continue', function()
    assert.run(30, [[
      local x = 0
      for i = 1, 10 {
        if i % 2 == 1 {
          continue
        }
        x += i
      }
      return x
    ]])
  end)
end)

describe('Declaration #5.1+', function()
  spec('local declaration', function()
    assert.run(1, [[
      local a = 1
      return a
    ]])
  end)

  spec('global declaration', function()
    assert.run(1, [[
      global a = 1
      return a
    ]])
  end)

  spec('module declaration', function()
    assert.run({ a = 1 }, 'module a = 1')
  end)

  spec('multiple declaration', function()
    assert.run(3, [[
      local a, b = 1, 2
      return a + b
    ]])
  end)

  spec('destructure declaration', function()
    assert.run(1, [[
      local a = { x = 1 }
      local { x } = a
      return x
    ]])
    assert.run('hello', [[
      local a = { 'hello', 'world' }
      local [ hello ] = a
      return hello
    ]])
  end)
end)

describe('DoBlock #5.1+', function()
  spec('do block', function()
    assert.run(1, [[
      local x
      do {
        x = 1
      }
      return x
    ]])
    assert.run(nil, [[
      do {
        local x
        x = 1
      }
      return x
    ]])
  end)
end)

describe('ForLoop #5.1+', function()
  spec('numeric for', function()
    assert.run(10, [[
      local x = 0
      for i = 1, 4 {
        x += i
      }
      return x
    ]])
    assert.run(4, [[
      local x = 0
      for i = 1, 4, 2 {
        x += i
      }
      return x
    ]])
  end)
  spec('generic for', function()
    assert.run(10, [[
      local x = 0
      for i, value in ipairs({ 1, 2, 8, 1 }) {
        x += i
      }
      return x
    ]])
    assert.run(12, [[
      local x = 0
      for i, value in ipairs({ 1, 2, 8, 1 }) {
        x += value
      }
      return x
    ]])
    assert.run(11, [[
      local x = 0
      for i, [a, b] in ipairs({{5, 6}}) {
        x += a + b
      }
      return x
    ]])
  end)
end)

describe('Function #5.1+', function()
  spec('local function', function()
    assert.run(2, [[
      local function test() {
        return 2
      }

      do {
        local function test() {
          return 1
        }
      }

      return test()
    ]])
  end)

  spec('global function', function()
    assert.run(1, [[
      function test() {
        return 2
      }

      do {
        global function test() {
          return 1
        }
      }

      return test()
    ]])
  end)

  spec('module function', function()
    local testModule = runErde([[
      module function test() {
        return 1
      }
    ]])
    assert.are.equal(1, testModule.test())
    assert.has_error(function()
      compile('module function a.b() {}')
    end)
  end)

  spec('method function', function()
    assert.run(1, [[
      local a = { x = 1 }

      function a:test() {
        return self.x
      }

      return a:test()
    ]])
  end)
end)

describe('Goto #jit #5.2+', function()
  spec('goto', function()
    assert.run(1, [[
      local x
      x = 1
      goto test
      x = 2
      ::test::
      return x
    ]]
    ) end)
end)

describe('IfElse #5.1+', function()
  spec('if', function()
    assert.run(1, 'if true { return 1 }')
    assert.run(nil, 'if false { return 1 }')
  end)

  spec('if + elseif', function()
    assert.run(2, [[
      if false {
        return 1
      } elseif true {
        return 2
      }
    ]])
  end)

  spec('if + else', function()
    assert.run(2, [[
      if false {
        return 1
      } else {
        return 2
      }
    ]])
  end)

  spec('if + elseif + else', function()
    assert.run(2, [[
      if false {
        return 1
      } elseif true {
        return 2
      } else {
        return 3
      }
    ]])
    assert.run(3, [[
      if false {
        return 1
      } elseif false {
        return 2
      } else {
        return 3
      }
    ]])
  end)
end)

describe('RepeatUntil #5.1+', function()
  spec('repeat until', function()
    assert.run(12, [[
      local x = 0
      repeat {
        x += 2
      } until x > 10
      return x
    ]])
  end)
end)

describe('Return #5.1+', function()
  spec('void return', function()
    assert.run(nil, 'return')
  end)
  spec('single return', function()
    assert.run(1, 'return 1')
  end)
  spec('multi return', function()
    assert.run(1, 'return (1, 2)')
  end)
end)

describe('TryCatch #5.1+', function()
  spec('try catch', function()
    assert.run(1, [[
      try {
        error('some error')
      } catch {
        return 1
      }
      return 2
    ]])
    assert.run(2, [[
      try {
        -- no error
      } catch {
        return 1
      }
      return 2
    ]])
    assert.run('some error', [[
      try {
        error({ value = 'some error' })
      } catch err {
        return err.value
      }
    ]])
    assert.run('some error', [[
      try {
        error({ value = 'some error' })
      } catch { value } {
        return value
      }
    ]])
  end)
end)

describe('WhileLoop #5.1+', function()
  spec('while loop', function()
    assert.run(10, [[
      local x = 0
      while x < 10 {
        x += 2
      }
      return x
    ]])
  end)
end)
