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

describe('blocks #5.1+', function()
  spec('update block declarations', function()
    assert_run(1, [[
      local x = 1

      do {
        global x = 0
      }

      local result = x
      _G.x = nil
      return result
    ]])

    assert_run(2, [[
      local x = 0
      local result

      do {
        global x = 2
        result = x
        _G.x = nil
      }

      return result
    ]])

    assert_run({ x = 3 }, [[
      module x = 0
      do { x = 3 }
    ]])
  end)
end)

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

  spec('use scope tables', function()
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

  spec('use scope tables', function()
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

  spec('use scope tables', function()
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

describe('terminal expression #5.1+', function()
  spec('transform Lua keywords', function()
    assert_run(1, [[
      local end = 1
      return end
    ]])

    assert_run(2, [[
      local x = { end = 2 }
      return x.end
    ]])

    assert_run(3, [[
      local end = { x = 3 }
      return end.x
    ]])
  end)

  spec('use scope tables', function()
    assert_run(1, [[
      global x = 0
      _G.x = 1
      local result = x
      _G.x = nil
      return result
    ]])

    assert_run({ x = 2 }, [[
      module x = 0
      _MODULE.x = 2
    ]])
  end)
end)

describe('for loop variables #5.1+', function()
  spec('transform Lua keywords', function()
    assert_run(1, [[
      local x = 0
      for end = 1, 1 { x = end }
      return x
    ]])

    assert_run(2, [[
      local x = 0
      for _, end in ipairs({ 2 }) { x = end }
      return x
    ]])
  end)

  spec('update block declarations', function()
    assert_run(1, [[
      global x = 1
      for x = 1, 1 { x = 0 }
      local result = _G.x
      _G.x = nil
      return result
    ]])

    assert_run(2, [[
      global x = 2
      for _, x in ipairs({ 0 }) { x = 0 }
      local result = _G.x
      _G.x = nil
      return result
    ]])

    assert_run({ x = 3 }, [[
      module x = 3
      for x = 1, 1 { x = 0 }
    ]])

    assert_run({ x = 4 }, [[
      module x = 4
      for _, x in ipairs({ 0 }) { x = 0 }
    ]])
  end)
end)

describe('goto #jit #5.2+', function()
  spec('transform Lua keywords', function()
    assert_run(1, [[
      local x = 1
      goto end
      x = 0
      ::end::
      return x
    ]])
  end)
end)

describe('variable assignment #5.1+', function()
  spec('transform Lua keywords', function()
    assert_run(1, [[
      local end = 0
      end = 1
      return end
    ]])

    assert_run(2, [[
      local x = {}
      x.end = 2
      return x.end
    ]])

    assert_run(3, [[
      local end = {}
      end.x = 3
      return end.x
    ]])
  end)

  spec('use scope tables', function()
    assert_run(1, [[
      local x = 0
      global x = 0
      x = 1
      local result = _G.x
      _G.x = nil
      return result
    ]])

    assert_run({ x = 2 }, [[
      module x = 0
      x = 2
    ]])
  end)
end)

describe('variable declaration #5.1+', function()
  spec('transform Lua keywords', function()
    assert_run(1, [[
      local end = 1
      return end
    ]])
  end)

  spec('use scope tables', function()
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
