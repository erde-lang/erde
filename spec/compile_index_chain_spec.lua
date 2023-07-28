-- -----------------------------------------------------------------------------
-- Index Chain Base
-- -----------------------------------------------------------------------------

spec('nested parens base #5.1+', function()
  assert_eval(1, '((({ x = 1 }))).x')
end)

-- -----------------------------------------------------------------------------
-- Dot Index
-- -----------------------------------------------------------------------------

spec('dot index #5.1+', function()
  assert_eval(1, '({ x = 1 }).x')

  assert_run(1, [[
    local a = { b = 1 }
    return a.b
  ]])
end)

-- -----------------------------------------------------------------------------
-- Bracket Index
-- -----------------------------------------------------------------------------

spec('bracket index #5.1+', function()
  assert_eval(2, '({ 2 })[1]')

  assert_run(1, [[
    local a = { [5] = 1 }
    return a[2 + 3]
  ]])
end)

-- -----------------------------------------------------------------------------
-- Function Call
-- -----------------------------------------------------------------------------

spec('function call #5.1+', function()
  assert_run(3, [[
    local a = (x, y) -> x + y
    return a(1, 2)
  ]])
end)

-- -----------------------------------------------------------------------------
-- Method Call
-- -----------------------------------------------------------------------------

spec('method call #5.1+', function()
  assert_run(3, [[
    local a = {
      b = (self, x) -> self.c + x,
      c = 1,
    }
    return a:b(2)
  ]])

  assert.has_error(function()
    compile('a:b')
  end)
end)

-- -----------------------------------------------------------------------------
-- Misc
-- -----------------------------------------------------------------------------

spec('chain #5.1+', function()
  assert_run(2, [[
    local a = { b = { 2 } }
    return a.b[1]
  ]])

  assert_run(2, [[
    local a = { { b = 2 } }
    return a[1].b
  ]])
end)

spec('string base #5.1+', function()
  assert_eval('yourstring', '"mystring":gsub("my", "your")')
  assert_eval('yourstring', "'mystring':gsub('my', 'your')")
  assert_eval('yourstring', "[[mystring]]:gsub('my', 'your')")
end)
