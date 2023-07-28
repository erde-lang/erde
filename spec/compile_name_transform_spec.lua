-- -----------------------------------------------------------------------------
-- Name Transforming
--
-- Erde will transform variable names in compiled code if:
--   - the name is a keyword in Lua, but not Erde (ex. `local end`)
--   or
--   - the declared scope was `module` or `global`
--
-- For example, `global` declarations will always transform the name to index `_G`:
--   `global my_var = 1` --> `_G.my_var = 1`
--   `print(my_var)`     --> `print(_G.my_var)`
--
-- A more interesting example is when declarations override previous ones:
--
-- local my_var = 1  --> local my_var = 1
-- global my_var = 2 --> _G.my_var = 2
-- print(my_var)     --> print(_G.my_var) -- 2!
-- -----------------------------------------------------------------------------

local lib = require('erde.lib')

-- -----------------------------------------------------------------------------
-- Destructuring
-- -----------------------------------------------------------------------------

describe('array destructuring #5.1+', function()
  spec('transform Lua keywords', function()
    assert_run(1, [[
      local [ end ] = { 1 }
      return end
    ]])

    assert_run(2, [[
      local [ end = 2 ] = {}
      return end
    ]])
  end)

  spec('use tracked scopes', function()
    assert_run(1, [[
      global [ x ] = { 1 }
      local result = _G.x
      _G.x = nil
      return result
    ]])

    assert_run(2, [[
      global [ x = 2 ] = {}
      local result = _G.x
      _G.x = nil
      return result
    ]])

    assert_run({ x = 3 }, [[
      module [ x ] = { 3 }
    ]])

    assert_run({ x = 4 }, [[
      module [ x = 4 ] = {}
    ]])
  end)

  spec('update block declarations', function()
    assert_run(1, [[
      local x = 0
      global [ x ] = {}
      x = 1
      local result = _G.x
      _G.x = nil
      return result
    ]])

    assert_run({ x = 2 }, [[
      local x = 0
      module [ x ] = {}
      x = 2
    ]])
  end)
end)

describe('map destructuring #5.1+', function()
  spec('transform Lua keywords', function()
    assert_run(1, [[
      local { end } = { end = 1 }
      return end
    ]])

    assert_run(2, [[
      local { end = 2 } = {}
      return end
    ]])

    assert_run(3, [[
      local { x: end } = { x = 3 }
      return end
    ]])
  end)

  spec('use tracked scopes', function()
    assert_run(1, [[
      global { x } = { x = 1 }
      local result = _G.x
      _G.x = nil
      return result
    ]])

    assert_run(2, [[
      global { x = 2 } = {}
      local result = _G.x
      _G.x = nil
      return result
    ]])

    assert_run({ nil, 3 }, [[
      global { x: y } = { x = 3 }
      local result = _G.y
      _G.y = nil
      return { _G.x, result }
    ]])

    assert_run({ x = 4 }, [[
      module { x } = { x = 4 }
    ]])

    assert_run({ x = 5 }, [[
      module { x = 5 } = {}
    ]])

    assert_run({ y = 6 }, [[
      module { x: y } = { x = 6 }
    ]])
  end)

  spec('update block declarations', function()
    assert_run(1, [[
      local x = 0
      global { x } = {}
      x = 1
      local result = _G.x
      _G.x = nil
      return result
    ]])

    assert_run({ x = 2 }, [[
      local x = 0
      module { x } = {}
      x = 2
    ]])
  end)
end)

-- -----------------------------------------------------------------------------
-- Functions
-- -----------------------------------------------------------------------------

describe('parameters #5.1+', function()
  spec('transform Lua keywords', function()
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

  spec('update block declarations', function()
    assert_run({ x = 1 }, [[
      module x = 1
      local f = x -> { x = 0 }
      f()
    ]])

    assert_run({ x = 2 }, [[
      module x = 2
      local f = (x) -> { x = 0 }
      f()
    ]])

    assert_run({ x = 3 }, [[
      module x = 3
      local f = (x = 0) -> {}
      f()
    ]])

    assert_run({ x = 4 }, [[
      module x = 4
      local f = (...x) -> { x = 0 }
      f()
    ]])
  end)
end)

describe('function declaration #5.1+', function()
  spec('transform Lua keywords', function()
    assert_run(1, [[
      local function end() { return 1 }
      return end()
    ]])

    assert_run(2, [[
      local x = {}
      function x.end() { return 2 }
      return x.end()
    ]])

    assert_run(3, [[
      local x = { y = 3 }
      function x:end() { return self.y }
      return x:end()
    ]])
  end)

  spec('use tracked scopes', function()
    assert_run('function', [[
      global function x() {}
      local result = type(_G.x)
      _G.x = nil
      return result
    ]])

    assert.is_function(lib.run([[
      module function x() {}
    ]]).x)
  end)

  spec('update block declarations', function()
    assert_run(1, [[
      local x = 0
      global function x() {}
      x = 1
      local result = _G.x
      _G.x = nil
      return result
    ]])

    assert_run({ x = 2 }, [[
      local x = 0
      module function x() {}
      x = 2
    ]])
  end)
end)

-- -----------------------------------------------------------------------------
-- Variable Declaration
-- -----------------------------------------------------------------------------

describe('variable declaration #5.1+', function()
  spec('transform Lua keywords', function()
    assert_run(1, [[
      local end = 1
      return end
    ]])
  end)

  spec('use tracked scopes', function()
    assert_run(1, [[
      local x = 0
      global x = 1
      local result = _G.x
      _G.x = nil
      return result
    ]])

    assert_run({ x = 2 }, [[
      local x = 0
      module x = 2
    ]])
  end)

  spec('update block declarations', function()
    assert_run(1, [[
      local x = 0
      global x = 1
      local result = x
      _G.x = nil
      return result
    ]])

    assert_run({ x = 2 }, [[
      local x = 0
      module x = 0
      x = 2
    ]])
  end)
end)
