-- -----------------------------------------------------------------------------
-- Local Declarations
-- -----------------------------------------------------------------------------

spec('local declarations #5.1+', function()
  assert_run(1, [[
    local a = 1
    return a
  ]])

  assert_run(1, [[
    local a = { x = 1 }
    local { x } = a
    return x
  ]])

  assert_run('hello', [[
    local a = { 'hello', 'world' }
    local [ hello ] = a
    return hello
  ]])

  assert_run(3, [[
    local a, b = 1, 2
    return a + b
  ]])
end)

-- -----------------------------------------------------------------------------
-- Module Declarations
-- -----------------------------------------------------------------------------

spec('module declarations #5.1+', function()
  assert_run({ a = 1 }, 'module a = 1')

  assert_run({ b = 1 }, [[
    local a = { b = 1 }
    module { b } = a
  ]])

  assert_run({ x = 1 }, [[
    local a = { x = 1 }
    module { x } = a
  ]])

  assert_run({ hello = 'hello' }, [[
    local a = { 'hello', 'world' }
    module [ hello ] = a
  ]])

  assert_run(nil, [[ return _MODULE ]])

  assert_run({ x = 1, y = 2 }, [[
    module y = 2
    _MODULE.x = 1
  ]])
end)

-- -----------------------------------------------------------------------------
-- Global Declarations
-- -----------------------------------------------------------------------------

spec('global declarations #5.1+', function()
  assert_run(1, [[
    global a = 1
    local result = _G.a
    _G.a = nil
    return result
  ]])

  assert_run(2, [[
    local a = 1
    global a = 2
    local result = a
    _G.a = nil
    return result
  ]])

  assert_run(2, [[
    local a = 1
    global a = 2
    local result = _G.a
    _G.a = nil
    return result
  ]])

  assert_run(1, [[
    local a = { x = 1 }
    global { x } = a
    local result = _G.x
    _G.x = nil
    return result
  ]])

  assert_run('hello', [[
    local a = { 'hello', 'world' }
    global [ hello ] = a
    local result = _G.hello
    _G.hello = nil
    return result
  ]])

  assert_run(1, [[
    local a = { 'hello', 'world' }
    global b, [ hello ] = 1, a
    local result = _G.b
    _G.b = nil
    _G.hello = nil
    return result
  ]])
end)
