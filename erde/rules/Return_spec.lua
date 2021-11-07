-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Return.parse', function()
  spec('rule', function()
    assert.are.equal('Return', parse.Return('return').rule)
  end)

  spec('return value', function()
    assert.are.equal('1', parse.Return('return 1').value.value)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Return.compile', function()
  spec('return', function()
    assert.run(1, compile.Return('return 1'))
  end)
end)
