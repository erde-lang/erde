local erde = require('erde')

-- TODO: Add destructuring args tests

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
  assert.are.equal(1, erde.eval([[
    local test = {}
    function test.x(a) { return a }
    return test.x(1)
  ]]))
  assert.are.equal(1, erde.eval([[
    local test = { y: {} }
    function test.y.z() { return 1 }
    return test.y.z()
  ]]))
  assert.are.equal(1, erde.eval([[
    local test = { y: 1 }
    function test:x() { return self.y }
    return test:x()
  ]]))
end)

spec('arrow functions', function()
  assert.are.equal(1, erde.eval([[
    local test = () -> {
      return 1
    }
    return test()
  ]]))
  assert.are.equal(1, erde.eval([[
    local test = () -> 1
    return test()
  ]]))
  assert.are.same({ x = 10 }, erde.eval([[
    local test = () -> ({ x: 10 })
    return test()
  ]]))
  assert.are.equal(10, erde.eval([[
    local test = { a: 10 }
    test.method = () => self.a
    return test:method()
  ]]))
end)

spec('params', function()
  assert.are.equal(4, erde.eval([[
    local test = a -> a + 2
    return test(2)
  ]]))
  assert.are.equal(5, erde.eval([[
    local test = (a, b) -> {
      return a + b
    }
    return test(2, 3)
  ]]))
  assert.are.equal(4, erde.eval([[
    local test = (a, b = 2) -> {
      return a + b
    }
    return test(2)
  ]]))
  assert.are.equal(6, erde.eval([[
    local test = (...) -> {
      local sum = 0
      for key, value in ipairs({ ... }) {
        sum = sum + value
      }
      return sum
    }
    return test(1, 2, 3)
  ]]))
  assert.are.equal(6, erde.eval([[
    local test = (...args) -> {
      local sum = 0
      for key, value in ipairs(args) {
        sum = sum + value
      }
      return sum
    }
    return test(1, 2, 3)
  ]]))
  assert.are.equal(9, erde.eval([[
    local test = (init = 1, ...rest) -> {
      for key, value in ipairs(rest) {
        init = init + value
      }
      return init
    }
    return test(2, 3, 4)
  ]]))
end)
