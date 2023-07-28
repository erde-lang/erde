-- -----------------------------------------------------------------------------
-- Do Block
-- -----------------------------------------------------------------------------

spec('do block #5.1+', function()
  assert_run(1, [[
    local a
    do { a = 1 }
    return a
  ]])

  assert_run(2, [[
    local a = 2
    do { local a = 0 }
    return a
  ]])
end)

-- -----------------------------------------------------------------------------
-- Block Declarations
-- -----------------------------------------------------------------------------

spec('update block declarations #5.1+', function()
  assert_run(1, [[
    local a = 1
    do { global a = 0 }
    local result = a
    _G.a = nil
    return result
  ]])

  assert_run(2, [[
    local a = 0
    local result

    do {
      global a = 2
      result = a
      _G.a = nil
    }

    return result
  ]])

  assert_run({ a = 3 }, [[
    module a = 0
    do { a = 3 }
  ]])
end)
