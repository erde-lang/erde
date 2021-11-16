-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Block.parse', function()
  spec('ruleName', function()
    assert.are.equal('Block', parse.Block('').ruleName)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Block.compile', function()
  spec('sanity check', function()
    assert.has.no_error(function()
      compile.Block('')
    end)
  end)
end)
