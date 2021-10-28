local unit = require('erde.compiler.unit')

spec('skinny arrow function', function()
  assert.erde_eval(1, unit.Expr('(() -> { return 1 })()'))
end)

spec('fat arrow function', function() end)

spec('arrow function implicit returns', function() end)
