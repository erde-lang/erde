-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('WhileLoop.parse', function()
  spec('rule', function()
    assert.are.equal('WhileLoop', unit.WhileLoop('while true {}').rule)
  end)

  spec('while loop', function()
    assert.has_subtable({
      rule = 'WhileLoop',
      cond = { value = 'true' },
      body = {},
    }, unit.WhileLoop(
      'while true {}'
    ))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('WhileLoop.compile', function()
  -- TODO
end)
