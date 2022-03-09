-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('DoBlock.parse', function()
  spec('do block', function()
    assert.subtable({
      body = {
        { ruleName = 'Assignment' },
      },
    }, parse.DoBlock(
      'do { a = 3 }'
    ))
  end)
  spec('do block expr', function()
    assert.subtable({
      exprList = { { ruleName = 'DoBlock' } },
    }, parse.Declaration(
      'local x = do { return 1 }'
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
    assert.run(
      1,
      compile.Block([[
        local x = do {
          return 1
        }
        return x
      ]])
    )
  end)
end)
