local erde = require('erde')

spec('function', function()
  assert.are.equal(1, erde.eval([[
    local function test() {
      return 1
    }
    return test()
  ]]))
end)
