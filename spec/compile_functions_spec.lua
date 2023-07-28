local compile = require('erde.compile')
local lib = require('erde.lib')

-- -----------------------------------------------------------------------------
-- Parameters
-- -----------------------------------------------------------------------------

describe('parameters #5.1+', function()
  spec('basics', function()
    assert_run(1, [[
      local a = (x) -> x
      return a(1)
    ]])

    assert_run(2, [[
      local a = x -> x + 1
      return a(1)
    ]])

    assert_run(2, [[
      local a = [ x ] -> x + 1
      return a({ 1 })
    ]])

    assert_run(2, [[
      local a = { x } -> x + 1
      return a({ x = 1 })
    ]])
  end)

  spec('defaults', function()
    assert_run(3, [[
      local a = (x, y = 2) -> x + y
      return a(1)
    ]])

    assert_run(3, [[
      local a = (x = 3, y) -> x + y
      return a(1, 2)
    ]])

    assert.has_error(function()
      compile('local a = x = 1 -> 1')
    end)
  end)

  spec('varargs', function()
    assert_run({ 1, 2 }, [[
      local a = (...) -> ({ ... })
      return a(1, 2)
    ]])

    assert_run({ 2, 3 }, [[
      local a = (x, ...) -> ({ ... })
      return a(1, 2, 3)
    ]])

    assert_run({ 1, 2 }, [[
      local a = (...x) -> x
      return a(1, 2)
    ]])

    assert_run({ 2, 3 }, [[
      local a = (x, ...y) -> y
      return a(1, 2, 3)
    ]])

    assert.has_error(function()
      compile('local a = ... -> 1')
    end)

    assert.has_error(function()
      compile('local a = (..., x) -> 1')
    end)
  end)

  spec('no varargs outside vararg function #5.1+', function()
    assert.has_error(function()
      compile('local x = () -> { print(...) }')
    end)
    assert.has_error(function()
      compile('local x = () -> ({ ... })')
    end)
    assert.has_error(function()
      compile('function x() { print(...) }')
    end)
    assert.has_no.errors(function()
      compile('print(...)') -- varargs allowed at top level in Lua!
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Arrow Functions
-- -----------------------------------------------------------------------------

describe('arrow function #5.1+', function()
  spec('implicit return', function()
    assert_run(1, [[
      local a = () -> 1
      return a()
    ]])

    assert_run(1, [[
      local a = (x) -> x
      return a(1)
    ]])

    assert_run(3, [[
      local a = (x, y) -> x + y
      return a(1, 2)
    ]])

    assert_run({ 1, 2 }, [[
      local a = (x, y) -> ({ x, y })
      return a(1, 2)
    ]])

    assert_run(3, [[
      local a = () -> (1, 2)
      local b, c = a()
      return b + c
    ]])

    assert_run(1, [[
      local a = x -> ({ x = x }).x
      return a(1)
    ]])

    assert.has_error(function()
      compile('local a = () -> { 1 }')
    end)
  end)

  spec('skinny', function()
    assert_eval('function', 'type(() -> {})')

    assert_run(1, [[
      local a = () -> { return 1 }
      return a()
    ]])

    assert_run(1, [[
      local a = x -> { return x }
      return a(1)
    ]])

    assert_run(1, [[
      local a = x -> { return x }
      return a(1)
    ]])

    local sum = lib.run('return (a, b) -> a + b')
    assert.are.equal(3, sum(1, 2))
  end)

  spec('fat', function()
    assert_eval('function', 'type(() => {})')

    assert_run(1, [[
      local a = { b = 1 }
      a.c = () => { return self.b }
      return a:c()
    ]])

    assert_run(3, [[
      local a = { b = 1 }
      a.c = x => { return self.b + x }
      return a:c(2)
    ]])

    local sum = lib.run('return (a, b) => a + b + self.c')
    assert.are.equal(6, sum({ c = 3 }, 1, 2))
  end)

  spec('iife', function()
    assert_eval(1, '(() -> { return 1 })()')
    assert_eval(1, '(() -> 1)()')
  end)
end)

-- -----------------------------------------------------------------------------
-- Function Declarations
-- -----------------------------------------------------------------------------

describe('function declaration #5.1+', function()
  spec('params', function()
    assert_run(1, [[
      local function a(x) {
        return x
      }
      return a(1)
    ]])

    assert_run(3, [[
      local function a(x, y = 2) {
        return x + y
      }
      return a(1)
    ]])

    assert_run(3, [[
      local function a(x = 3, y) {
        return x + y
      }
      return a(1, 2)
    ]])

    assert_run({ 1, 2 }, [[
      local function a(...) {
        return { ... }
      }
      return a(1, 2)
    ]])

    assert_run({ 2, 3 }, [[
      local function a(x, ...) {
        return { ... }
      }
      return a(1, 2, 3)
    ]])

    assert_run({ 1, 2 }, [[
      local function a(...x) {
        return x
      }
      return a(1, 2)
    ]])

    assert_run({ 2, 3 }, [[
      local function a(x, ...y) {
        return y
      }
      return a(1, 2, 3)
    ]])

    assert_run({ 1, 2, { 3, 4 } }, [[
      local function a(x, y = 2, ...) {
        return { x, y, { ... } }
      }
      return a(1, 2, 3, 4)
    ]])

    assert_run({ 1, 2, { 3, 4 } }, [[
      local function a(x, y = 2, ...z) {
        return { x, y, z }
      }
      return a(1, 2, 3, 4)
    ]])

    assert_run(2, [[
      local function a([ x ]) {
        return x + 1
      }
      return a({ 1 })
    ]])

    assert_run(2, [[
      local function a({ x }) {
        return x + 1
      }
      return a({ x = 1 })
    ]])
  end)

  spec('local', function()
    assert_run(2, [[
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

    assert_run(1, [[
      local function test() {
        return 2
      }

      do {
        function test() {
          return 1
        }
      }

      return test()
    ]])

    assert.has_error(function()
      compile('local function a.b() {}')
    end)
  end)

  spec('global', function()
    assert_run(2, [[
      local function test() {
        return 2
      }

      do {
        global function test() {
          return 1
        }
      }

      local result = test()
      _G.test = nil
      return result
    ]])

    assert_run(1, [[
      local function test() {
        return 2
      }

      do {
        global function test() {
          return 1
        }
      }

      local result = _G.test()
      _G.test = nil
      return result
    ]])
  end)

  spec('module', function()
    local testModule = lib.run([[
      module function test() {
        return 1
      }
    ]])

    assert.are.equal(1, testModule.test())

    assert.has_error(function()
      compile('module function a.b() {}')
    end)
  end)

  spec('method', function()
    assert_run(1, [[
      local a = { x = 1 }

      function a:test() {
        return self.x
      }

      return a:test()
    ]])
  end)
end)
