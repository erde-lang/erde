local unit = require('erde.compiler.unit')

spec('compile terminals', function()
  assert.erde_compile_expr(true, unit.Terminal('true'))
  assert.erde_compile_expr(false, unit.Terminal('false'))
  assert.erde_compile_expr(nil, unit.Terminal('nil'))
  assert.erde_compile_expr(1, unit.Terminal('1'))
  -- TODO
  -- assert.erde_compile_expr(..., unit.Terminal('...').value)
  -- assert.erde_compile_expr(3, unit.Terminal('(1 + 2)'))
end)
