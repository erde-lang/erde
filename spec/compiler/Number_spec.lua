local unit = require('erde.compiler.unit')

spec('compile integer', function()
  assert.erde_compile_expr(9, unit.Number('9'))
  assert.erde_compile_expr(43, unit.Number('43'))
end)

spec('compile hex', function()
  assert.erde_compile_expr(0x4, unit.Number('0x4'))
  assert.erde_compile_expr(0xd, unit.Number('0xd'))
  assert.erde_compile_expr(0Xf, unit.Number('0Xf'))
  assert.erde_compile_expr(0xa8F, unit.Number('0xa8F'))
  assert.erde_compile_expr(0xfp2, unit.Number('0xfp2'))
  assert.erde_compile_expr(0xfP2, unit.Number('0xfP2'))

  -- TODO: compiler tests for different lua versions
  -- assert.erde_compile_expr(0xfp+2, unit.Number('0xfp+2'))
  -- assert.erde_compile_expr(0xfp-2, unit.Number('0xfp-2'))
end)

spec('compile integer exponent', function()
  assert.erde_compile_expr(9e2, unit.Number('9e2'))
  assert.erde_compile_expr(9E21, unit.Number('9E21'))
  assert.erde_compile_expr(9e+2, unit.Number('9e+2'))
  assert.erde_compile_expr(9e-2, unit.Number('9e-2'))
end)

spec('compile float', function()
  assert.erde_compile_expr(.34, unit.Number('.34'))
  assert.erde_compile_expr(0.3, unit.Number('0.3'))
  assert.erde_compile_expr(10.33, unit.Number('10.33'))
end)

spec('compile float exponent', function()
  assert.erde_compile_expr(9.2e2, unit.Number('9.2e2'))
  assert.erde_compile_expr(9.01E21, unit.Number('9.01E21'))
  assert.erde_compile_expr(0.1e+2, unit.Number('0.1e+2'))
  assert.erde_compile_expr(.8e-2, unit.Number('.8e-2'))
end)
