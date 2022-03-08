-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Return.parse', function()
  spec('return values', function()
    assert.subtable({
      '1',
    }, parse.Return('return 1'))
    assert.subtable({
      '1',
      '2',
    }, parse.Return('return 1, 2'))
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
