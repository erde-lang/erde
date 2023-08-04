local compile = require('erde.compile')
local lib = require('erde.lib')

-- -----------------------------------------------------------------------------
-- Parameters
-- -----------------------------------------------------------------------------

spec('parameters #5.1+', function()
  assert_run(1, [[
    local a = (b) -> b
    return a(1)
  ]])

  assert_run(2, [[
    local a = b -> b + 1
    return a(1)
  ]])

  assert_run(3, [[
    local a = [ b ] -> b + 1
    return a({ 2 })
  ]])

  assert_run(4, [[
    local a = { b } -> b + 1
    return a({ b = 3 })
  ]])
end)

spec('parameter defaults #5.1+', function()
  assert_run(1, [[
    local a = (b, c = 2) -> b + c
    return a(-1)
  ]])

  assert_run(2, [[
    local a = (b = 1, c) -> b + c
    return a(nil, 1)
  ]])

  assert_run(3, [[
    local a = (b = 1, c) -> b + c
    return a(2, 1)
  ]])

  assert.has_error(function()
    compile('local a = b = 1 -> 1')
  end)
end)

spec('parameter varargs #5.1+', function()
  assert_run({ 1, 2 }, [[
    local a = (...) -> ({ ... })
    return a(1, 2)
  ]])

  assert_run({ 3, 4 }, [[
    local a = (b, ...) -> ({ ... })
    return a(0, 3, 4)
  ]])

  assert_run({ 5, 6 }, [[
    local a = (...b) -> b
    return a(5, 6)
  ]])

  assert_run({ 7, 8 }, [[
    local a = (b, ...c) -> c
    return a(0, 7, 8)
  ]])

  assert.has_error(function()
    compile('local a = ... -> 1')
  end)

  assert.has_error(function()
    compile('local a = (..., b) -> 1')
  end)
end)

spec('parameters transform Lua keywords #5.1+', function()
  assert_run(1, [[
    local f = end -> end
    return f(1)
  ]])

  assert_run(2, [[
    local f = (end) -> end
    return f(2)
  ]])

  assert_run({ 3 }, [[
    local f = (...end) -> end
    return f(3)
  ]])
end)

spec('parameters update block declarations #5.1+', function()
  assert_run({ a = 1 }, [[
    module a = 1
    local f = a -> { a = 0 }
    f()
  ]])

  assert_run({ a = 2 }, [[
    module a = 2
    local f = (a) -> { a = 0 }
    f()
  ]])

  assert_run({ a = 3 }, [[
    module a = 3
    local f = (a = 0) -> {}
    f()
  ]])

  assert_run({ a = 4 }, [[
    module a = 4
    local f = (...a) -> { a = 0 }
    f()
  ]])
end)

-- -----------------------------------------------------------------------------
-- Arrow Functions
-- -----------------------------------------------------------------------------

spec('skinny arrow function #5.1+', function()
  assert_eval('function', 'type(() -> {})')

  assert_run(1, [[
    local a = () -> { return 1 }
    return a()
  ]])

  assert_run(2, [[
    local a = b -> { return b }
    return a(2)
  ]])

  assert_run(3, [[
    local a = b -> { return b }
    return a(3)
  ]])

  local sum = lib.run('return (a, b) -> a + b')
  assert.are.equal(4, sum(1, 3))
end)

spec('fat arrow function #5.1+', function()
  assert_eval('function', 'type(() => {})')

  assert_run(1, [[
    local a = { b = 1 }
    a.c = () => { return self.b }
    return a:c()
  ]])

  assert_run(2, [[
    local a = { b = 1 }
    a.c = d => { return self.b + d }
    return a:c(1)
  ]])

  local sum = lib.run('return (a, b) => a + b + self.c')
  assert.are.equal(3, sum({ c = -1 }, 3, 1))
end)

spec('arrow function implicit return #5.1+', function()
  assert_run(1, [[
    local a = () -> 1
    return a()
  ]])

  assert_run(2, [[
    local a = (b) -> b
    return a(2)
  ]])

  assert_run(3, [[
    local a = (b, c) -> b + c
    return a(1, 2)
  ]])

  assert_run({ 4, 5 }, [[
    local a = (b, c) -> ({ b, c })
    return a(4, 5)
  ]])

  assert_run(6, [[
    local a = () -> (2, 4)
    local b, c = a()
    return b + c
  ]])

  assert_run(7, [[
    local a = b -> ({ b = b }).b
    return a(7)
  ]])

  assert.has_error(function()
    compile('local a = () -> { 1 }')
  end)
end)

spec('iife #5.1+', function()
  assert_eval(1, '(() -> { return 1 })()')
  assert_eval(2, '(() -> 2)()')
end)

spec('arrow function source map #5.1 jit', function()
  assert_source_map(1, [[
    local a = 1 + () -> 1
  ]])

  assert_source_map(2, [[
    local a = 1 +
    () -> 1
  ]])
end)

-- -----------------------------------------------------------------------------
-- Function Declarations
-- -----------------------------------------------------------------------------

spec('local function declaration #5.1+', function()
  assert_run(1, [[
    local function a() {
      return 1
    }

    do {
      local function a() {
        return 2
      }
    }

    return a()
  ]])

  assert_run(2, [[
    local function a() {
      return 1
    }

    do {
      function a() {
        return 2
      }
    }

    return a()
  ]])

  assert_run(nil, [[
    local function a() {
      return 1
    }

    do {
      function a() {
        return 2
      }
    }

    return _G.a
  ]])

  assert.has_error(function()
    compile('local function a.b() {}')
  end)
end)

spec('global function declaration #5.1+', function()
  assert_run(1, [[
    local function a() {
      return 1
    }

    do {
      global function a() {
        return 2
      }
    }

    local result = a()
    _G.a = nil
    return result
  ]])

  assert_run(2, [[
    local function a() {
      return 1
    }

    do {
      global function a() {
        return 2
      }
    }

    local result = _G.a()
    _G.a = nil
    return result
  ]])

  assert_run(3, [[
    function a() { return 3 }
    local result = _G.a()
    _G.a = nil
    return result
  ]])
end)

spec('module function declaration #5.1+', function()
  local testModule = lib.run([[
    module function a() {
      return 1
    }
  ]])

  assert.are.equal(1, testModule.a())

  assert.has_error(function()
    compile('module function a.b() {}')
  end)
end)

spec('method declaration method #5.1+', function()
  assert_run(1, [[
    local a = { b = 1 }

    function a:c() {
      return self.b
    }

    return a:c()
  ]])
end)

spec('function declaration transform Lua keywords #5.1+', function()
  assert_run(1, [[
    local function end() { return 1 }
    return end()
  ]])

  assert_run(2, [[
    local a = {}
    function a.end() { return 2 }
    return a.end()
  ]])

  assert_run(3, [[
    local a = { b = 3 }
    function a:end() { return self.b }
    return a:end()
  ]])
end)

spec('function declaration use tracked scopes #5.1+', function()
  assert_run('function', [[
    global function a() {}
    local result = type(_G.a)
    _G.a = nil
    return result
  ]])

  assert.is_function(lib.run([[
    module function a() {}
  ]]).a)
end)

spec('function declaration update block declarations #5.1+', function()
  assert_run(1, [[
    local a = 0
    global function a() {}
    a = 1
    local result = _G.a
    _G.a = nil
    return result
  ]])

  assert_run({ a = 2 }, [[
    local a = 0
    module function a() {}
    a = 2
  ]])
end)

spec('function declaration source map #5.1+', function()
  assert_source_map(1, [[
    function a.b() {}
  ]])

  assert_source_map(2, [[

    function a
    .b() {}
  ]])

  assert_source_map(3, [[


    function
    a
    :b() {}
  ]])
end)

-- -----------------------------------------------------------------------------
-- Misc
-- -----------------------------------------------------------------------------

spec('no varargs outside vararg function #5.1+', function()
  assert.has_no.errors(function()
    compile('print(...)') -- varargs allowed at top level in Lua!
  end)

  assert.has_error(function()
    compile('local a = () -> ({ ... })')
  end)

  assert.has_error(function()
    compile('local a = () -> { print(...) }')
  end)

  assert.has_error(function()
    compile([[
      local a = (...) -> {
        local b = () -> {
          print(...)
        }
      }
    ]])
  end)

  assert.has_error(function()
    compile('function a() { print(...) }')
  end)

  assert.has_error(function()
    compile([[
      function a(...) {
        function b() {
          print(...)
        }
      }
    ]])
  end)
end)
