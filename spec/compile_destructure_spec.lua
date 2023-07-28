-- -----------------------------------------------------------------------------
-- Array Destructure
-- -----------------------------------------------------------------------------

spec('array destructure #5.1+', function()
  assert_run(1, [[
    local [ a ] = { 1 }
    return a
  ]])

  assert_run({ 2, 3 }, [[
    local [ a, b ] = { 2, 3 }
    return { a, b }
  ]])

  assert_run(4, [[
    local [ a ] = { 4, 5 }
    return a
  ]])
end)

spec('array destructure defaults #5.1+', function()
  assert_run(1, [[
    local [ a = 1 ] = {}
    return a
  ]])

  assert_run(2, [[
    local [ a = 0 ] = { 2 }
    return a
  ]])

  assert_run(3, [[
    local [ a = 3 ] = { nil }
    return a
  ]])
end)

spec('array destructure transform Lua keywords #5.1+', function()
  assert_run(1, [[
    local [ end ] = { 1 }
    return end
  ]])

  assert_run(2, [[
    local [ end = 2 ] = {}
    return end
  ]])
end)

spec('array destructure use tracked scopes #5.1+', function()
  assert_run(1, [[
    global [ a ] = { 1 }
    local result = _G.a
    _G.a = nil
    return result
  ]])

  assert_run(2, [[
    global [ a = 2 ] = {}
    local result = _G.a
    _G.a = nil
    return result
  ]])

  assert_run({ a = 3 }, [[
    module [ a ] = { 3 }
  ]])

  assert_run({ a = 4 }, [[
    module [ a = 4 ] = {}
  ]])
end)

spec('array destructure update block declarations #5.1+', function()
  assert_run(1, [[
    local a = 0
    global [ a ] = {}
    a = 1
    local result = _G.a
    _G.a = nil
    return result
  ]])

  assert_run({ a = 2 }, [[
    local a = 0
    module [ a ] = {}
    a = 2
  ]])
end)

-- -----------------------------------------------------------------------------
-- Map Destructure
-- -----------------------------------------------------------------------------

spec('map destructure #5.1+', function()
  assert_run(1, [[
    local { a } = { a = 1 }
    return a
  ]])

  assert_run({ 2, 3 }, [[
    local { a, b } = { a = 2, b = 3 }
    return { a, b }
  ]])

  assert_run(4, [[
    local { a } = { a = 4, b = 5 }
    return a
  ]])
end)

spec('map destructure defaults #5.1+', function()
  assert_run(1, [[
    local { a = 1 } = {}
    return a
  ]])

  assert_run(2, [[
    local { a = 0 } = { a = 2 }
    return a
  ]])

  assert_run(3, [[
    local { a = 3 } = { a = nil }
    return a
  ]])
end)

spec('map destructure alias #5.1+', function()
  assert_run(nil, [[
    local { a: b } = { a = 1 }
    return a
  ]])

  assert_run(1, [[
    local { a: b } = { a = 1 }
    return b
  ]])

  assert_run(2, [[
    local { a: b } = { a = 2, b = 0 }
    return b
  ]])
end)

spec('map destructure transform Lua keywords #5.1+', function()
  assert_run(1, [[
    local { end } = { end = 1 }
    return end
  ]])

  assert_run(2, [[
    local { end = 2 } = {}
    return end
  ]])

  assert_run(3, [[
    local { a: end } = { a = 3 }
    return end
  ]])
end)

spec('map destructure use tracked scopes #5.1+', function()
  assert_run(1, [[
    global { a } = { a = 1 }
    local result = _G.a
    _G.a = nil
    return result
  ]])

  assert_run(2, [[
    global { a = 2 } = {}
    local result = _G.a
    _G.a = nil
    return result
  ]])

  assert_run({ nil, 3 }, [[
    global { a: b } = { a = 3 }
    local result = _G.b
    _G.b = nil
    return { _G.a, result }
  ]])

  assert_run({ a = 4 }, [[
    module { a } = { a = 4 }
  ]])

  assert_run({ a = 5 }, [[
    module { a = 5 } = {}
  ]])

  assert_run({ b = 6 }, [[
    module { a: b } = { a = 6 }
  ]])
end)

spec('map destructure update block declarations #5.1+', function()
  assert_run(1, [[
    local a = 0
    global { a } = {}
    a = 1
    local result = _G.a
    _G.a = nil
    return result
  ]])

  assert_run({ a = 2 }, [[
    local a = 0
    module { a } = {}
    a = 2
  ]])
end)
