local lib = require('erde.lib')

spec('return #5.1+', function()
  assert_run(nil, 'return')
  assert_run(1, 'return 1')
  assert_run(2, 'return (2)')
  assert.are.equal('function', type(lib.run('return () -> 1')))

  assert_run(3, [[
    return (() -> {
      local a, b = 1, 2
      return a + b
    })()
  ]])

  assert_run({ 1, 2, 3, 4 }, [[
    local function a() {
      return (
        1,
        2,
        3,
        4,
      )
    }

    return { a() }
  ]])

  assert.has_error(function()
    compile('return 1 print()')
  end)

  assert.has_error(function()
    compile([[
      if true {
        return 1
        print()
      }
    ]])
  end)
end)
