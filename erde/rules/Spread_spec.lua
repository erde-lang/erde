-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Spread.parse', function()
  spec('ruleName', function()
    assert.are.equal('Spread', parse.Spread('...x').ruleName)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Spread.compile', function()
  spec('spread', function() end)
end)
