-- -----------------------------------------------------------------------------
-- Goto
-- -----------------------------------------------------------------------------

spec('goto #jit #5.2+', function()
  assert_run(1, [[
    local a
    a = 1
    goto test
    a = 2
    ::test::
    return a
  ]])
end)

spec('goto transform Lua keywords #jit #5.2+', function()
  assert_run(1, [[
    local x = 1
    goto end
    x = 0
    ::end::
    return x
  ]])
end)

-- -----------------------------------------------------------------------------
-- If Else
-- -----------------------------------------------------------------------------

spec('if #5.1+', function()
  assert_run(1, 'if true { return 1 }')
  assert_run(2, 'if false { return 0 }; return 2')
end)

spec('if + elseif #5.1+', function()
  assert_run(1, [[
    if true {
      return 1
    } elseif true {
      return 0
    }
  ]])

  assert_run(2, [[
    if false {
      return 0
    } elseif true {
      return 2
    }
  ]])
end)

spec('if + else #5.1+', function()
  assert_run(1, [[
    if true {
      return 1
    } else {
      return 0
    }
  ]])

  assert_run(2, [[
    if false {
      return 0
    } else {
      return 2
    }
  ]])
end)

spec('if + elseif + else #5.1+', function()
  assert_run(1, [[
    if true {
      return 1
    } elseif true {
      return 0
    } else {
      return 0
    }
  ]])

  assert_run(2, [[
    if false {
      return 0
    } elseif true {
      return 2
    } else {
      return 0
    }
  ]])

  assert_run(3, [[
    if false {
      return 0
    } elseif false {
      return 0
    } else {
      return 3
    }
  ]])
end)
