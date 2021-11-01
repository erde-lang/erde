local unit = require('erde.compiler.unit')

spec('skinny arrow function', function()
  assert.eval(1, unit.OptChain('(() -> { return 1 })()'))
  assert.eval(2, unit.OptChain('((x) -> { return x + 1 })(1)'))
  assert.eval(3, unit.OptChain('((x, y) -> { return x + y })(1, 2)'))
end)

spec('fat arrow function', function()
  assert.eval(1, unit.OptChain('(() => { return 1 })()'))
  assert.eval(2, unit.OptChain('((x) -> { return x + 1 })(1)'))
  assert.eval(3, unit.OptChain('((x, y) -> { return x + y })(1, 2)'))
end)

spec('arrow function implicit returns', function() end)
