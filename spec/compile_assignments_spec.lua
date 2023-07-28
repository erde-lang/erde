local compile = require('erde.compile')

-- -----------------------------------------------------------------------------
-- Non-Operator Assignments
-- -----------------------------------------------------------------------------

spec('single assignment #5.1+', function()
  assert_run(1, [[
    local a
    a = 1
    return a
  ]])

  assert_run(2, [[
    local a = {}
    a.b = 2
    return a.b
  ]])

  assert_run(3, [[
    local a = {}
    (() -> a)().b = 3
    return a.b
  ]])

  assert_run(4, [[
    local a = { b = 0 }
    local c = { end = () -> a }
    c:end().b = 4
    return a.b
  ]])

  assert.has_error(function()
    compile('a() = 0')
  end)

  assert.has_error(function()
    compile('a, b() = 0')
  end)
end)

spec('multi assignment #5.1+', function()
  assert_run({ 1, 2 }, [[
    local a, b
    a, b = 1, 2
    return { a, b }
  ]])

  assert_run({ 3, 4 }, [[
    local a, b = {}, {}
    a.c, b.d = 3, 4
    return { a.c, b.d }
  ]])

  assert_run({ 5, 6 }, [[
    local a = { b = 0 }
    local c = { end = () -> a }
    c.d, c:end().b = 5, 6
    return { c.d, a.b }
  ]])
end)

describe('assignment transform Lua keywords #5.1+', function()
  assert_run(1, [[
    local end = 0
    end = 1
    return end
  ]])

  assert_run(2, [[
    local a = {}
    a.end = 2
    return a.end
  ]])

  assert_run(3, [[
    local end = {}
    end.a = 3
    return end.a
  ]])
end)

spec('assignment use tracked scopes #5.1+', function()
  assert_run(1, [[
    local a = 0
    global a = 0
    a = 1
    local result = _G.a
    _G.a = nil
    return result
  ]])

  assert_run({ a = 2 }, [[
    module a = 0
    a = 2
  ]])
end)

-- -----------------------------------------------------------------------------
-- Operator Assignments
-- -----------------------------------------------------------------------------

spec('single operator assignment #5.1+', function()
  assert_run(1, [[
    local a = -1
    a += 2
    return a
  ]])

  assert_run(2, [[
    local a = { b = -1 }
    a.b += 3
    return a.b
  ]])

  assert_run(3, [[
    local a = { b = -1 }
    (() -> a)().b += 4
    return a.b
  ]])

  assert_run(4, [[
    local a = { b = -1 }
    local c = { end = () -> a }
    c:end().b += 5
    return a.b
  ]])

  assert.has_error(function()
    compile('a() += 0')
  end)

  assert.has_error(function()
    compile('a, b() += 0')
  end)
end)

spec('multi operator assignment #5.1+', function()
  assert_run({ 1, 2 }, [[
    local a, b = -1, -1
    a, b += 2, 3
    return { a, b }
  ]])

  assert_run({ 3, 4 }, [[
    local a, b = { c = -1 }, { d = -1 }
    a.c, b.d += 4, 5
    return { a.c, b.d }
  ]])

  assert_run({ 5, 6 }, [[
    local a = { b = -1 }
    local c = { d = -1, end = () -> a }
    c.d, c:end().b += 6, 7
    return { c.d, a.b }
  ]])

  assert_run({ 7, 8 }, [[
    local a = () -> (8, 9)
    local b, c = -1, -1
    b, c += a()
    return { b, c }
  ]])
end)

spec('operator assignment transform Lua keywords #5.1+', function()
  assert_run(1, [[
    local end = -1
    end += 2
    return end
  ]])

  assert_run(2, [[
    local a = { end = -1 }
    a.end += 3
    return a.end
  ]])

  assert_run(3, [[
    local end = { a = -1 }
    end.a += 4
    return end.a
  ]])
end)

spec('operator assignment use tracked scopes #5.1+', function()
  assert_run(1, [[
    local a = -1
    global a = -1
    a += 2
    local result = _G.a
    _G.a = nil
    return result
  ]])

  assert_run({ a = 2 }, [[
    module a = -1
    a += 3
  ]])
end)

spec('operator assignment mixed precedence', function()
  assert_run(1, [[
    local a = -1
    a += true && 2 || 0
    return a
  ]])
end)

spec('operator assignment minimize repeated index chains #5.1+', function()
  assert_run({ 1, 1 }, [[
    local a = { b = -1 }
    local call_counter = 0

    local function c() {
      call_counter += 1
      return a
    }

    c().b += 2
    return { call_counter, a.b }
  ]])

  assert_run({ 1, 2 }, [[
    local a, b = {}, { c = -1 }
    local index_counter = 0

    setmetatable(a, {
      __index = key => {
        index_counter += 1
        return b[key]
      },
    })

    a.c += 3
    return { index_counter, a.c }
  ]])
end)
