-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Return.parse', function()
  spec('rule', function()
    assert.are.equal('Return', parse.Return('return').rule)
  end)

  spec('return values', function()
    assert.has_subtable({
      { value = '1' },
    }, parse.Return('return 1'))
    assert.has_subtable({
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
