-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Return.parse', function()
  spec('return values', function()
    assert.subtable({
      { value = '1' },
    }, parse.Return('return 1'))
    assert.subtable({
      { value = '1' },
      { value = '2' },
    }, parse.Return(
      'return 1, 2'
    ))
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
