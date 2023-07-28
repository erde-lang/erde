local compile = require('erde.compile')

-- -----------------------------------------------------------------------------
-- Break
-- -----------------------------------------------------------------------------

spec('break #5.1+', function()
  assert_run(1, [[
    local a = 0

    while true {
      a += 1
      break
    }

    return a
  ]])

  assert_run(2, [[
    local a = 2

    while true {
      if true { break }
      a += 1
    }

    return a
  ]])

  assert_run(3, [[
    local a = 0

    for i = 1, 3 {
      for j = 1, 4 {
        a += 1
        break
      }
    }

    return a
  ]])

  assert.has_error(function()
    compile('if true { break }')
  end)
end)


describe('code following break', function()
  spec('disallow #5.1 #jit', function()
    assert.has_error(function()
      compile([[
        while true {
          break
          print()
        }
      ]])
    end)
  end)

  spec('allow #5.2+', function()
    assert.has.no_error(function()
      compile([[
        while true {
          break
          print()
        }
      ]])
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Continue
-- -----------------------------------------------------------------------------

spec('continue #5.1+', function()
  assert_run({ 1, 2 }, [[
    local a, b = 1, 0

    for i = 1, 2 {
      b += 1
      continue
      a += 1
    }

    return { a, b }
  ]])

  assert_run({ 3, 4 }, [[
    local a, b = 3, 0

    for i = 1, 2 {
      for j = 1, 2 {
        b += 1
        continue
        a += 1
      }
    }

    return { a, b }
  ]])

  assert.has_error(function()
    compile('if true { continue }')
  end)
end)

-- -----------------------------------------------------------------------------
-- For Loop
-- -----------------------------------------------------------------------------

spec('numeric for loop #5.1+', function()
  assert_run({ 1, 2, 3 }, [[
    local a = {}
    for i = 1, 3 { table.insert(a, i) }
    return a
  ]])

  assert_run({ 2, 4, 6 }, [[
    local a = {}
    for i = 2, 6, 2 { table.insert(a, i) }
    return a
  ]])
end)

spec('generic for loop #5.1+', function()
  assert_run({ 1, 2, 3 }, [[
    local a = {}
    for i, value in ipairs({ 0, 0, 0 }) { table.insert(a, i) }
    return a
  ]])

  assert_run({ 4, 5, 6 }, [[
    local a = {}
    for i, value in ipairs({ 4, 5, 6 }) { table.insert(a, value) }
    return a
  ]])

  assert_run({ 7, 8 }, [[
    local a = {}
    for i, [ b ] in ipairs({ { 7 }, { 8 } }) { table.insert(a, b) }
    return a
  ]])
end)

spec('for loop transform Lua keywords #5.1+', function()
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

spec('for loop update block declarations #5.1+', function()
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

-- -----------------------------------------------------------------------------
-- Repeat Until
-- -----------------------------------------------------------------------------

spec('repeat until #5.1+', function()
  assert_run(10, [[
    local a = 0
    repeat { a += 1 } until a > 9
    return a
  ]])
end)

-- -----------------------------------------------------------------------------
-- While Loop
-- -----------------------------------------------------------------------------

spec('while loop  #5.1+', function()
  assert_run(10, [[
    local a = 0
    while a < 10 { a += 1 }
    return a
  ]])
end)
