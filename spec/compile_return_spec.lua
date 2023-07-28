spec('return #5.1+', function()
  assert_run(nil, 'return')

  assert_run(1, 'return 1')

  assert_run(1, 'return (1, 2)')

  assert_run(1, [[
    return (
      1,
      2,
    )
  ]])

  assert.has_error(function()
    compile('return 1 if true {}')
  end)

  assert.has_error(function()
    compile([[
      if true {
        return 1
        print(32)
      }
    ]])
  end)
end)
