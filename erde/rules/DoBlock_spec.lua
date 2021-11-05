-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('DoBlock.parse', function()
  spec('rule', function()
    assert.are.equal('DoBlock', parse.DoBlock('do {}').rule)
  end)

  spec('do block', function()
    assert.has_subtable({
      body = {
        { rule = 'Assignment' },
      },
    }, parse.DoBlock(
      'do { a = 3 }'
    ))
  end)

  spec('do block return ', function()
    assert.has_subtable({
      hasReturn = true,
    }, parse.DoBlock(
      'do { return 1 }'
    ))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('DoBlock.compile', function()
  -- TODO
end)
