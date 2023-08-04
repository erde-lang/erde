spec('tables #5.1+', function()
  assert_eval({ 10 }, '{ 10 }')
  assert_eval({ x = 2 }, '{ x = 2 }')
  assert_eval({ [3] = 1 }, '{ [1 + 2] = 1 }')
  assert_eval({ x = { y = 1 } }, '{ x = { y = 1 } }')
end)

spec('tables source map #5.1 jit', function()
  assert_source_map(1, [[
    local a = 1 + {}
  ]])

  assert_source_map(2, [[
    local a = 1 +
    {}
  ]])
end)
