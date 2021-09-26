local erde = require('erde')

spec('if else', function()
  assert.are.equal(1, erde.eval([[
    if true {
      return 1
    }
  ]]))
  assert.are.equal(2, erde.eval([[
    if false {
      return 1
    } elseif true {
      return 2
    }
  ]]))
  assert.are.equal(3, erde.eval([[
    if false {
      return 1
    } elseif false {
      return 2
    } else {
      return 3
    }
  ]]))
  assert.are.equal(4, erde.eval([[
    if false {
      return 1
    } elseif false {
      return 2
    } elseif false {
      return 3
    } else {
      return 4
    }
  ]]))
end)

spec('numeric for', function()
  assert.are.equal(15, erde.eval([[
    local x = 0
    for i = 1, 5 {
      x = x + i
    }
    return x
  ]]))
  assert.are.equal(15, erde.eval([[
    local x = 0
    for i = 5, 1, -1 {
      x = x + i
    }
    return x
  ]]))
end)

spec('generic for', function()
  assert.are.equal(30, erde.eval([[
    local x = 0
    local t = { 5, 10, 15 }
    for key, value in ipairs(t) {
      x = x + value
    }
    return x
  ]]))
  assert.are.equal(6, erde.eval([[
    local x = 0
    local t = { 5, 10, 15 }
    for key, value in ipairs(t) {
      x = x + key
    }
    return 6
  ]]))
end)
