local erde = require('erde')

spec('table construction', function()
  assert.are.same({ 1, 2, 3 }, erde.eval('return { 1, 2, 3 }'))
  assert.are.same({ 1, 2, 3 }, erde.eval('return { 1, 2, 3, }'))
  assert.are.same({ a = 'b' }, erde.eval('return { a: "b" }'))
  assert.are.same({ a = 'b' }, erde.eval('local a = "b" return { :a }'))
  assert.are.same({ ['x-y'] = 1 }, erde.eval('return { "x-y": 1 }'))
  assert.are.same({ 1, a = 'b', 2 }, erde.eval('return { 1, a: "b", 2 }'))
end)

spec('destructure', function()
  assert.are.same(6, erde.eval([[
    local { a, b, c } = { 1, 2, 3 }
    return a + b + c
  ]]))
  assert.are.same(6, erde.eval([[
    local { :a, b, c } = { a: 1, 2, 3 }
    return a + b + c
  ]]))
  assert.are.same(6, erde.eval([[
    local { a, b, c = 3 } = { 1, 2 }
    return a + b + c
  ]]))
  assert.are.same(3, erde.eval([[
    local x = { a: { 1, 2 } }
    local { :a { b, c } } = x
    return b + c
  ]]))
  assert.are.same(3, erde.eval([[
    local x = {}
    local { :a { b, c } = { 1, 2 } } = x
    return b + c
  ]]))
  assert.are.same(3, erde.eval([[
    local x = { { 1, 2 } }
    local { { b, c } } = x
    return b + c
  ]]))
  assert.are.same(true, erde.eval([[
    local { ?{ b } } = {}
    return b == nil
  ]]))
  assert.are.same(true, erde.eval([[
    local x = { a: { } }
    local { :a { :b? { c } } } = x
    return c == nil
  ]]))
  assert.are.same(1, erde.eval([[
    local x = { a: { b: { 1 } } }
    local { :a { :b? { c } } } = x
    return c
  ]]))
end)
