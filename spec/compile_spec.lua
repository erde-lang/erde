--
-- TODO: Add separate section for non rule compiles
-- Ex) Terminals, keyword errors, etc.
--

-- -----------------------------------------------------------------------------
-- ArrowFunction
-- -----------------------------------------------------------------------------

describe('ArrowFunction', function()
  spec('skinny arrow function', function()
    assert.eval('function', compile.OptChain('type(() -> {})'))
    assert.run(
      3,
      compile.Block([[
        local a = (x, y) -> { return x + y }
        return a(1, 2)
      ]])
    )
  end)

  spec('fat arrow function', function()
    assert.eval('function', compile.OptChain('type(() => {})'))
    assert.run(
      2,
      compile.Block([[
        local a = { b = 1 }
        a.c = () => { return self.b + 1 }
        return a:c()
      ]])
    )
  end)

  spec('arrow function iife', function()
    assert.eval(1, compile.OptChain('(() -> { return 1 })()'))
  end)

  spec('arrow function implicit returns', function()
    assert.run(
      1,
      compile.Block([[
        local a = () -> 1
        return a()
      ]])
    )
    assert.run(
      3,
      compile.Block([[
        local a = () -> (1, 2)
        local b, c = a()
        return b + c
      ]])
    )
  end)

  spec('arrow function implicit params', function()
    assert.run(
      2,
      compile.Block([[
        local a = x -> { return x + 1 }
        return a(1)
      ]])
    )
    assert.run(
      2,
      compile.Block([[
        local a = [ x ] -> { return x + 1 }
        return a({ 1 })
      ]])
    )
    assert.run(
      2,
      compile.Block([[
        local a = { x } -> { return x + 1 }
        return a({ x = 1 })
      ]])
    )
    assert.run(
      2,
      compile.Block([[
        local a = { b = 1 }
        a.c = x => { return self.b + x }
        return a:c(1)
      ]])
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- Assignment
-- -----------------------------------------------------------------------------

describe('Assignment', function()
  spec('name assignment', function()
    assert.run(
      1,
      compile.Block([[
        local a
        a = 1
        return a
      ]])
    )
  end)

  spec('optchain assignment', function()
    assert.run(
      1,
      compile.Block([[
        local a = {}
        a.b = 1
        return a.b
      ]])
    )
    assert.run(
      nil,
      compile.Block([[
        local a
        a?.b = 1
        return a?.b
      ]])
    )
  end)

  spec('multiple name assignment', function()
    assert.run(
      3,
      compile.Block([[
        local a, b
        a, b = 1, 2
        return a + b
      ]])
    )
  end)

  spec('multiple optchain assignment', function()
    assert.run(
      3,
      compile.Block([[
        local a, b = {}, {}
        a.c, b.d = 1, 2
        return a.c + b.d
      ]])
    )
    assert.run(
      -1,
      compile.Block([[
        local a, b
        a?.c, b?.d = 1, 2
        return a?.c ?? b?.d ?? -1
      ]])
    )
  end)

  spec('binop assignment', function()
    assert.run(
      3,
      compile.Block([[
        local a = 1
        a += 2
        return a
      ]])
    )
    assert.run(
      4,
      compile.Block([[
        local a = 5
        a &= 6
        return a
      ]])
    )
    assert.run(
      8,
      compile.Block([[
        local a, b = 1, 2
        a, b += 2, 3
        return a + b
      ]])
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- Binop
-- -----------------------------------------------------------------------------

describe('Binop', function()
  spec('left associative binop precedence', function()
    assert.run(5, compile.Block('return 1 * 2 + 3'))
    assert.run(7, compile.Block('return 1 + 2 * 3'))
    assert.run(11, compile.Block('return 1 + 2 * 3 + 4'))
  end)

  spec('right associative binop precedence', function()
    assert.run(512, compile.Block('return 2 ^ 3 ^ 2'))
    assert.run(7, compile.Block('return 2 ^ 2 + 3'))
  end)

  spec('binop parens', function()
    assert.run(25, compile.Block('return 5 * (2 + 3)'))
  end)

  spec('ternary operator', function()
    assert.run(3, compile.Block('return false ? 2 : 3'))
    assert.run(2, compile.Block('return true ? 2 : 3'))
    assert.run(7, compile.Block('return false ? -2 : 3 + 4'))
  end)
end)

-- -----------------------------------------------------------------------------
-- Break
-- -----------------------------------------------------------------------------

describe('Break', function()
  spec('break', function()
    assert.run(
      6,
      compile.Block([[
        local x = 0
        while x < 10 {
          x += 2
          if x > 4 {
            break
          }
        }
        return x
      ]])
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- Continue
-- -----------------------------------------------------------------------------

describe('Continue', function()
  spec('continue', function()
    assert.run(
      30,
      compile.Block([[
        local x = 0
        for i = 1, 10 {
          if i % 2 == 1 {
            continue
          }
          x += i
        }
        return x
      ]])
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- Declaration
-- -----------------------------------------------------------------------------

describe('Declaration', function()
  spec('local declaration', function()
    assert.run(
      1,
      compile.Block([[
        local a = 1
        return a
      ]])
    )
  end)

  spec('global declaration', function()
    assert.run(
      1,
      compile.Block([[
        global a = 1
        return a
      ]])
    )
  end)

  spec('module declaration', function()
    assert.run({ a = 1 }, compile.Module('module a = 1'))
  end)

  spec('main declaration', function()
    assert.run(1, compile.Module('main a = 1'))
  end)

  spec('multiple declaration', function()
    assert.run(
      3,
      compile.Block([[
        local a, b = 1, 2
        return a + b
      ]])
    )
  end)

  spec('destructure declaration', function()
    assert.run(
      1,
      compile.Block([[
        local a = { x = 1 }
        local { x } = a
        return x
      ]])
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- DoBlock
-- -----------------------------------------------------------------------------

describe('DoBlock', function()
  spec('do block', function()
    assert.run(
      1,
      compile.Block([[
        local x
        do {
          x = 1
        }
        return x
      ]])
    )
    assert.run(
      nil,
      compile.Block([[
        do {
          local x
          x = 1
        }
        return x
      ]])
    )
    assert.run(
      1,
      compile.Block([[
        local x = do {
          return 1
        }
        return x
      ]])
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- ForLoop
-- -----------------------------------------------------------------------------

describe('ForLoop', function()
  spec('numeric for', function()
    assert.run(
      10,
      compile.Block([[
        local x = 0
        for i = 1, 4 {
          x += i
        }
        return x
      ]])
    )
    assert.run(
      4,
      compile.Block([[
        local x = 0
        for i = 1, 4, 2 {
          x += i
        }
        return x
      ]])
    )
  end)
  spec('generic for', function()
    assert.run(
      10,
      compile.Block([[
        local x = 0
        for i, value in ipairs({ 1, 2, 8, 1 }) {
          x += i
        }
        return x
      ]])
    )
    assert.run(
      12,
      compile.Block([[
        local x = 0
        for i, value in ipairs({ 1, 2, 8, 1 }) {
          x += value
        }
        return x
      ]])
    )
    assert.run(
      11,
      compile.Block([[
        local x = 0
        for i, [a, b] in ipairs({{5, 6}}) {
          x += a + b
        }
        return x
      ]])
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- Function
-- -----------------------------------------------------------------------------

describe('Function', function()
  spec('local function', function()
    assert.run(
      2,
      compile.Block([[
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
    )
  end)

  spec('global function', function()
    assert.run(
      1,
      compile.Block([[
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
    )
  end)

  spec('module function', function()
    local testModule = runErde(compile.Module([[
      module function test() {
        return 1
      }
    ]]))
    assert.are.equal(1, testModule.test())
    assert.has_error(function()
      compile.Module('module function a.b() {}')
    end)
  end)

  spec('main function', function()
    local testModule = runErde(compile.Module([[
      main function test() {
        return 1
      }
    ]]))
    assert.are.equal(1, testModule())
    assert.has_error(function()
      compile.Module('main function a.b() {}')
    end)
  end)

  spec('method function', function()
    assert.run(
      1,
      compile.Block([[
        local a = { x = 1 }

        function a:test() {
          return self.x
        }

        return a:test()
      ]])
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- Goto
-- -----------------------------------------------------------------------------

describe('Goto', function()
  spec('goto', function()
    assert.run(
      1,
      compile.Block([[
        local x
        x = 1
        goto test
        x = 2
        ::test::
        return x
      ]])
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- IfElse
-- -----------------------------------------------------------------------------

describe('IfElse', function()
  spec('if', function()
    assert.run(1, compile.Block('if true { return 1 }'))
    assert.run(nil, compile.Block('if false { return 1 }'))
  end)

  spec('if + elseif', function()
    assert.run(
      2,
      compile.Block([[
        if false {
          return 1
        } elseif true {
          return 2
        }
      ]])
    )
  end)

  spec('if + else', function()
    assert.run(
      2,
      compile.Block([[
        if false {
          return 1
        } else {
          return 2
        }
      ]])
    )
  end)

  spec('if + elseif + else', function()
    assert.run(
      2,
      compile.Block([[
        if false {
          return 1
        } elseif true {
          return 2
        } else {
          return 3
        }
      ]])
    )
    assert.run(
      3,
      compile.Block([[
        if false {
          return 1
        } elseif false {
          return 2
        } else {
          return 3
        }
      ]])
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- Module
-- -----------------------------------------------------------------------------

describe('Module', function()
  spec('hoisted declarations', function()
    assert.run(
      4,
      compile.Module([[
        local function test() {
          return x
        }

        local x = 4
        return test()
      ]])
    )
  end)
  spec('hoisted functions', function()
    assert.run(
      5,
      compile.Module([[
        local function test1() {
          return test2()
        }

        local function test2() {
          return 5
        }

        return test1()
      ]])
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- OptChain
-- -----------------------------------------------------------------------------

describe('OptChain', function()
  spec('optchain base', function()
    assert.eval(1, compile.OptChain('({ x = 1 }).x'))
  end)

  spec('optchain dotIndex', function()
    assert.run(
      1,
      compile.Block([[
        local a = { b = 1 }
        return a.b
      ]])
    )
    assert.run(
      nil,
      compile.Block([[
        local a = {}
        return a?.b
      ]])
    )
  end)

  spec('optchain bracketIndex', function()
    assert.run(
      1,
      compile.Block([[
        local a = { [5] = 1 }
        return a[2 + 3]
      ]])
    )
    assert.run(
      nil,
      compile.Block([[
        local a = {}
        return a?[2 + 3]
      ]])
    )
  end)

  spec('optchain functionCall', function()
    assert.run(
      3,
      compile.Block([[
        local a = (x, y) -> x + y
        return a(1, 2)
      ]])
    )
    assert.run(
      nil,
      compile.Block([[
        local a
        return a?(1, 2)
      ]])
    )
  end)

  spec('optchain method', function()
    assert.run(
      3,
      compile.Block([[
        local a = {
          b = (self, x) -> self.c + x,
          c = 1,
        }
        return a:b(2)
      ]])
    )
    assert.run(
      nil,
      compile.Block([[
        local a
        return a?:b(1, 2)
      ]])
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- Params
-- -----------------------------------------------------------------------------

describe('Params', function()
  spec('params', function()
    assert.run(
      3,
      compile.Block([[
        local function test(a, b) {
          return a + b
        }
        return test(1, 2)
      ]])
    )
  end)

  spec('optional params', function()
    assert.run(
      2,
      compile.Block([[
        local function test(a = 2) {
          return a
        }
        return test()
      ]])
    )
  end)

  spec('params varargs', function()
    assert.run(
      'hello.world',
      compile.Block([[
        local function test(...) {
          return table.concat({ ... }, '.')
        }
        return test('hello', 'world')
      ]])
    )
    assert.run(
      'hello.world',
      compile.Block([[
        local function test(...args) {
          return table.concat(args, '.')
        }
        return test('hello', 'world')
      ]])
    )
  end)

  spec('destructure params', function()
    assert.run(
      3,
      compile.Block([[
        local function test({ a }, b) {
          return a + b
        }

        local x = { a = 1 }
        return test(x, 2)
      ]])
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- RepeatUntil
-- -----------------------------------------------------------------------------

describe('RepeatUntil', function()
  spec('repeat until', function()
    assert.run(
      12,
      compile.Block([[
        local x = 0
        repeat {
          x += 2
        } until x > 10
        return x
      ]])
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

describe('Return', function()
  spec('return', function()
    assert.run(1, compile.Return('return 1'))
  end)
  spec('return', function()
    assert.run(1, compile.Return('return (1, 2)'))
  end)
end)

-- -----------------------------------------------------------------------------
-- Self
-- -----------------------------------------------------------------------------

describe('Self', function()
  spec('dotIndex', function()
    assert.run(
      1,
      compile.Block([[
        local x = { y = 1 }
        function x:test() {
          return $y
        }
        return x:test()
      ]])
    )
  end)
  spec('numberIndex', function()
    assert.run(
      8,
      compile.Block([[
        local x = { 9, 8, 7 }
        function x:test() {
          return $2
        }
        return x:test()
      ]])
    )
  end)
  spec('self', function()
    assert.run(
      1,
      compile.Block([[
        local x = { y = 1 }
        function x:test() {
          return $.y
        }
        return x:test()
      ]])
    )
  end)

  -- -----------------------------------------------------------------------------
  -- Spread
  -- -----------------------------------------------------------------------------

  describe('Spread', function()
    spec('table spread', function()
      assert.run(
        21,
        compile.Block([[
        local a = { 3, 4, 5 }
        local function sum(t) {
          local answer = 0
          for i, value in ipairs(t) {
            answer += value
          }
          return answer
        }
        return sum({ 1, 2, ...a, 6 })
      ]])
      )
    end)
    spec('function spread', function()
      assert.run(
        12,
        compile.Block([[
        local a = { 3, 4, 5 }
        local function sum(x, y, z) {
          return x + y + z
        }
        return sum(...a)
      ]])
      )
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- String
-- -----------------------------------------------------------------------------

describe('String', function()
  spec('compile short string', function()
    assert.are.equal('""', compile.String('""'))
    assert.are.equal('"hello"', compile.String('"hello"'))
    assert.are.equal("'hello'", compile.String("'hello'"))
    assert.are.equal("'hello\\nworld'", compile.String("'hello\\nworld'"))
    assert.are.equal("'\\\\'", compile.String("'\\\\'"))
  end)

  spec('compile long string', function()
    assert.eval('hello world', compile.String('[[hello world]]'))
    assert.eval(' hello\nworld', compile.String('[[ hello\nworld]]'))
    assert.eval('a{bc}d', compile.String('[[a\\{bc}d]]'))
    assert.eval('a[[b', compile.String('[=[a[[b]=]'))
  end)

  spec('compile interpolation', function()
    assert.eval('hello 3', compile.String('"hello {3}"'))
    assert.eval('hello 3', compile.String("'hello {3}'"))
    assert.eval('hello 3', compile.String('[[hello {3}]]'))
  end)
end)

-- -----------------------------------------------------------------------------
-- Table
-- -----------------------------------------------------------------------------

describe('Table', function()
  spec('table numberKey', function()
    assert.eval({ 10 }, compile.Table('{ 10 }'))
  end)

  spec('table nameKey', function()
    assert.eval({ x = 2 }, compile.Table('{ x = 2 }'))
  end)

  spec('table exprKey', function()
    assert.eval({ [3] = 1 }, compile.Table('{ [1 + 2] = 1 }'))
  end)

  spec('nested table', function()
    assert.eval({ x = { y = 1 } }, compile.Table('{ x = { y = 1 } }'))
  end)
end)

-- -----------------------------------------------------------------------------
-- TryCatch
-- -----------------------------------------------------------------------------

describe('TryCatch', function()
  spec('try catch', function()
    assert.run(
      1,
      compile.Block([[
        try {
          error('some error')
        } catch() {
          return 1
        }
        return 2
      ]])
    )
    assert.run(
      2,
      compile.Block([[
        try {
          -- no error
        } catch() {
          return 1
        }
        return 2
      ]])
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- Unop
-- -----------------------------------------------------------------------------

describe('Unop', function()
  spec('unops', function()
    assert.run(-6, compile.Block('return 2 * -3'))
    assert.run(-6, compile.Block('return -2 * 3'))
    assert.run(-8, compile.Block('return -2 ^ 3'))
  end)
end)

-- -----------------------------------------------------------------------------
-- WhileLoop
-- -----------------------------------------------------------------------------

describe('WhileLoop', function()
  spec('while loop', function()
    assert.run(
      10,
      compile.Block([[
        local x = 0
        while x < 10 {
          x += 2
        }
        return x
      ]])
    )
  end)
end)
