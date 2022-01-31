local utils = require('erde.utils')

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

-- Most tests in tokenizer_spec. Here we just test for valid tokens that are
-- invalid as numbers
spec('Number.parse', function()
  assert.has_error(function()
    parse.Number('x3')
  end)
  assert.has_error(function()
    parse.Number('e2')
  end)
  assert.has_error(function()
    parse.Number('.e2')
  end)
  assert.has_error(function()
    parse.Number('.1ef')
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Number.compile', function()
  spec('integer', function()
    assert.eval(9, compile.Number('9'))
    assert.eval(43, compile.Number('43'))
  end)

  spec('hex', function()
    assert.eval(0x4, compile.Number('0x4'))
    assert.eval(0xd, compile.Number('0xd'))
    assert.eval(0Xf, compile.Number('0Xf'))
    assert.eval(0xa8F, compile.Number('0xa8F'))
  end)

  spec('floats', function()
    assert.eval(0.34, compile.Number('.34'))
    assert.eval(0.3, compile.Number('0.3'))
    assert.eval(10.33, compile.Number('10.33'))
  end)

  spec('exponents', function()
    assert.eval(9e2, compile.Number('9e2'))
    assert.eval(9.2E21, compile.Number('9.2E21'))
    assert.eval(9e+2, compile.Number('9e+2'))
    assert.eval(0.8e-2, compile.Number('.8e-2'))
  end)
end)
