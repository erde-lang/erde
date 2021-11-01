local unit = require('erde.compiler.unit')

spec('skinny arrow function', function()
  assert.eval('function', unit.OptChain('type(() -> {})'))
  assert.run(
    2,
    unit.Block([[
      local a = (x) -> { return x + 1 }
      return a(1)
    ]])
  )
  assert.run(
    3,
    unit.Block([[
      local a = (x, y) -> { return x + y }
      return a(1, 2)
    ]])
  )
end)

spec('fat arrow function', function()
  assert.eval('function', unit.OptChain('type(() => {})'))
  assert.run(
    2,
    unit.Block([[
      local a = { b: 1 }
      a.c = () => { return self.b + 1 }
      return a:c()
    ]])
  )
  assert.run(
    2,
    unit.Block([[
      local a = { b: 1 }
      a.c = (x) => { return self.b + x }
      return a:c(1)
    ]])
  )
end)

spec('arrow function implicit returns', function()
  assert.eval(1, unit.OptChain('(() => 1)()'))
end)

spec('arrow function iife', function()
  assert.eval(1, unit.OptChain('(() => 1)()'))
end)
