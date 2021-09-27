local erde = require('erde')

spec('function declaration', function()
  assert.are.equal(1, erde.eval([[
    local function test() {
      return 1
    }
    return test()
  ]]))
  assert.are.equal(5, erde.eval([[
    local function test(a, b) {
      return a + b
    }
    return test(2, 3)
  ]]))
end)
