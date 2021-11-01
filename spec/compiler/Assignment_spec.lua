local unit = require('erde.compiler.unit')

spec('assignment', function()
  assert.run(
    1,
    unit.Block([[
      local a
      a = 1
      return a
    ]])
  )
  assert.run(
    1,
    unit.Block([[
      local a = {}
      a.b = 1
      return a.b
    ]])
  )
end)

spec('multiple assignment', function()
  assert.run(
    3,
    unit.Block([[
      local a, b
      a, b = 1, 2
      return a + b
    ]])
  )
  assert.run(
    3,
    unit.Block([[
      local a, b = {}, {}
      a.c, b.d = 1, 2
      return a.c + b.d
    ]])
  )
end)

spec('binop assignment', function()
  assert.run(
    3,
    unit.Block([[
      local a = 1
      a += 2
      return a
    ]])
  )
  assert.run(
    4,
    unit.Block([[
      local a = 5
      a .&= 6
      return a
    ]])
  )
end)
