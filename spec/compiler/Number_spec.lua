local unit = require('erde.compiler.unit')

spec('integer', function()
  assert.erde_eval(9, unit.Number('9'))
  assert.erde_eval(43, unit.Number('43'))
end)

spec('hex', function()
  assert.erde_eval(0x4, unit.Number('0x4'))
  assert.erde_eval(0xd, unit.Number('0xd'))
  assert.erde_eval(0Xf, unit.Number('0Xf'))
  assert.erde_eval(0xa8F, unit.Number('0xa8F'))
  assert.erde_eval(0xfp2, unit.Number('0xfp2'))
  assert.erde_eval(0xfP2, unit.Number('0xfP2'))

  -- TODO: compiler tests for different lua versions
  -- assert.erde_eval(0xfp+2, unit.Number('0xfp+2'))
  -- assert.erde_eval(0xfp-2, unit.Number('0xfp-2'))
end)

spec('floats', function()
  assert.erde_eval(.34, unit.Number('.34'))
  assert.erde_eval(0.3, unit.Number('0.3'))
  assert.erde_eval(10.33, unit.Number('10.33'))
end)

spec('exponents', function()
  assert.erde_eval(9e2, unit.Number('9e2'))
  assert.erde_eval(9.2E21, unit.Number('9.2E21'))
  assert.erde_eval(9e+2, unit.Number('9e+2'))
  assert.erde_eval(.8e-2, unit.Number('.8e-2'))
end)
