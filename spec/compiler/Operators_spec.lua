local erde = require('erde')

spec('unary op', function()
  assert.are.equal(-2, erde.eval('return -2'))
  assert.are.equal(true, erde.eval('return ~false'))
  assert.are.equal(true, erde.eval('return ~(1 == 2)'))
  assert.are.equal(3, erde.eval('return #{1, 2, 3}'))
end)

spec('ternary op', function()
  assert.are.equal(2, erde.eval('return false ? 1 : 2'))
  assert.are.equal(1, erde.eval('return true ? 1 : 2'))
end)

spec('arithmetic binop', function()
  assert.are.equal(6, erde.eval('return 1 + 2 + 3'))
  assert.are.equal(3, erde.eval('return 5 - 2'))
  assert.are.equal(8, erde.eval('return 5 - -3'))
  assert.are.equal(2, erde.eval('return 5 // 2'))
end)

spec('logical binop', function()
  assert.are.equal(false, erde.eval('return false & false'))
  assert.are.equal(false, erde.eval('return false & true'))
  assert.are.equal(true, erde.eval('return true & true'))
  assert.are.equal(false, erde.eval('return false | false'))
  assert.are.equal(true, erde.eval('return false | true'))
  assert.are.equal(true, erde.eval('return true | true'))
end)

spec('relational binop', function()
  assert.are.equal(true, erde.eval('return 3 < 5'))
  assert.are.equal(false, erde.eval('return 4 >= 5'))
end)

spec('bitwise op', function()
  assert.are.equal(1, erde.eval('return .~2 .& 3'))
  assert.are.equal(1, erde.eval('return 1 .& 1'))
  assert.are.equal(3, erde.eval('return 2 .| 1'))
  assert.are.equal(2, erde.eval('return 1 .<< 1'))
  assert.are.equal(1, erde.eval('return 2 .>> 1'))
  assert.are.equal(2, erde.eval('return 3 .~ 1'))
end)

spec('misc binop', function()
  assert.are.equal('helloworld', erde.eval("return 'hello' .. 'world'"))
  assert.are.equal(4, erde.eval('return nil ?? 4'))
end)

spec('assign op', function()
  assert.are.equal(5, erde.eval([[
    local x = 1
    x += 4
    return x
  ]]))
  assert.are.equal(true, erde.eval([[
    local x = false
    x |= true
    return x
  ]]))
  assert.are.equal(1, erde.eval([[
    local x = nil
    x ??= 1
    return x
  ]]))
end)

spec('pipes', function()
  assert.are.equal(5, erde.eval([[
    local function test(a, b) { return a + b }
    return 4 >> test(1)
  ]]))
  assert.are.equal(5, erde.eval([[
    local function test(a) { return a + 1 }
    return 4 >> test
  ]]))
  assert.are.equal(5, erde.eval([[
    local function test(a) { return a + 1 }
    return 4 >> (test | nil)
  ]]))
end)
