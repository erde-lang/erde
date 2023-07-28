-- -----------------------------------------------------------------------------
-- Local Declarations
-- -----------------------------------------------------------------------------

spec('local declarations #5.1+', function()
  assert_run(1, [[
    local a = 1
    return a
  ]])

  assert_run(2, [[
    local a = { b = 2 }
    local { b } = a
    return b
  ]])

  assert_run(3, [[
    local a = { 3 }
    local [ b ] = a
    return b
  ]])

  assert_run(4, [[
    local a, b = 1, 3
    return a + b
  ]])
end)

-- -----------------------------------------------------------------------------
-- Module Declarations
-- -----------------------------------------------------------------------------

spec('module declarations #5.1+', function()
  assert_run({ a = 1 }, 'module a = 1')

  assert_run({ b = 2 }, [[
    local a = { b = 2 }
    module { b } = a
  ]])

  assert_run({ b = 3 }, [[
    local a = { b = 3 }
    module { b } = a
  ]])

  assert_run({ b = 4 }, [[
    local a = { 4 }
    module [ b ] = a
  ]])

  assert_run({ a = 5, b = 6 }, [[
    module a = 5
    _MODULE.b = 6
  ]])

  assert_run(nil, [[ return _MODULE ]])
end)

-- -----------------------------------------------------------------------------
-- Global Declarations
-- -----------------------------------------------------------------------------

spec('global declarations #5.1+', function()
  assert_run(1, [[
    global a = 1
    local result = a
    _G.a = nil
    return result
  ]])

  assert_run(2, [[
    global a = 2
    local result = _G.a
    _G.a = nil
    return result
  ]])

  assert_run(3, [[
    local a = { b = 3 }
    global { b } = a
    local result = _G.b
    _G.b = nil
    return result
  ]])

  assert_run(4, [[
    local a = { 4 }
    global [ b ] = a
    local result = _G.b
    _G.b = nil
    return result
  ]])

  assert_run({ 5, 6 }, [[
    global a, b = 5, 6
    local result = { _G.a, _G.b }
    _G.a = nil
    _G.b = nil
    return result
  ]])
end)

-- -----------------------------------------------------------------------------
-- Misc
-- -----------------------------------------------------------------------------

spec('transform Lua keywords #5.1+', function()
  assert_run(1, [[
    local end = 1
    return end
  ]])
end)

spec('use tracked scopes #5.1+', function()
  assert_run(1, [[
    local a = 0
    global a = 1
    local result = _G.a
    _G.a = nil
    return result
  ]])

  assert_run({ a = 2 }, [[
    local a = 0
    module a = 2
  ]])
end)

spec('update block declarations #5.1+', function()
  assert_run(1, [[
    local a = 0
    global a = 1
    local result = a
    _G.a = nil
    return result
  ]])

  assert_run({ a = 2 }, [[
    local a = 0
    module a = 0
    a = 2
  ]])
end)
