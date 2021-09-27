local erde = require('erde')

spec('function declaration', function()
  assert.are.equal(1, erde.eval([[
    function test() {
      return 1
    }
    return test()
  ]]))
  assert.are.equal(5, erde.eval([[
    function test(a, b) {
      return a + b
    }
    return test(2, 3)
  ]]))
  assert.are.equal(1, erde.eval([[
    function test(a) { return a }
    do {
      local function test(a) {
        return -a
      }
    }
    return test(1)
  ]]))
  assert.are.equal(-1, erde.eval([[
    function test(a) { return a }
    local function test(a) {
      return -a
    }
    return test(1)
  ]]))
end)
