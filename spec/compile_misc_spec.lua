-- -----------------------------------------------------------------------------
-- Ambiguous Syntax
-- -----------------------------------------------------------------------------

spec('ambiguous syntax #5.1+', function()
  assert_run(1, [[
    local a = 1
    local b = a;(() -> 0)()
    return b
  ]])

  assert_run(2, [[
    local a = 2
    local b = a
    (() -> 0)()
    return b
  ]])

  assert_run(3, [[
    local a = f -> f
    local b = a(() -> 3)()
    return b
  ]])
end)

-- -----------------------------------------------------------------------------
-- Throwaway Parentheses
--
-- Often used to throwaway excessive values, in particular for functions that
-- return multiple values.
-- -----------------------------------------------------------------------------

spec('retain throwaway parens #5.1+', function()
  assert_run(1, [[
    local a = () -> (1, 2)
    local b, c = (a())
    return b
  ]])

  assert_run(nil, [[
    local a = () -> (1, 2)
    local b, c = (a())
    return c
  ]])
end)
