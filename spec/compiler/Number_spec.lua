local unit = require('erde.compiler.unit')

spec('integer', function()
  assert.eval(9, unit.Number('9'))
  assert.eval(43, unit.Number('43'))
end)

spec('hex', function()
  assert.eval(0x4, unit.Number('0x4'))
  assert.eval(0xd, unit.Number('0xd'))
  assert.eval(0Xf, unit.Number('0Xf'))
  assert.eval(0xa8F, unit.Number('0xa8F'))
  assert.eval(0xfp2, unit.Number('0xfp2'))
  assert.eval(0xfP2, unit.Number('0xfP2'))

  -- TODO: compiler tests for different lua versions
  -- assert.eval(0xfp+2, unit.Number('0xfp+2'))
  -- assert.eval(0xfp-2, unit.Number('0xfp-2'))
end)

spec('floats', function()
  assert.eval(.34, unit.Number('.34'))
  assert.eval(0.3, unit.Number('0.3'))
  assert.eval(10.33, unit.Number('10.33'))
end)

spec('exponents', function()
  assert.eval(9e2, unit.Number('9e2'))
  assert.eval(9.2E21, unit.Number('9.2E21'))
  assert.eval(9e+2, unit.Number('9e+2'))
  assert.eval(.8e-2, unit.Number('.8e-2'))
end)
