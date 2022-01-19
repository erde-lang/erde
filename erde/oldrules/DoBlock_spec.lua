-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('DoBlock.parse', function()
  spec('do block', function()
    assert.has_subtable({
      body = {
        { ruleName = 'Assignment' },
      },
    }, parse.DoBlock(
      'do { a = 3 }'
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
end)
