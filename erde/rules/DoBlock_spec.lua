-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('DoBlock.parse', function()
  spec('ruleName', function()
    assert.are.equal('DoBlock', parse.DoBlock('do {}').ruleName)
  end)

  spec('do block', function()
    assert.has_subtable({
      body = {
        { ruleName = 'Assignment' },
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
  spec('do block', function()
    assert.run(
      1,
      compile.Block([[
        local x
        do {
          x = 1
        }
        return x
      ]])
    )
    assert.run(
      nil,
      compile.Block([[
        do {
          local x
          x = 1
        }
        return x
      ]])
    )
  end)
  spec('do block return', function()
    assert.run(
      2,
      compile.Block([[
        local x = do {
          local y = 1
          return y + 1
        }
        return x
      ]])
    )
    assert.run(
      nil,
      compile.Block([[
        local x = do {
          local y = 1
          return y + 1
        }
        return y
      ]])
    )
  end)
end)
