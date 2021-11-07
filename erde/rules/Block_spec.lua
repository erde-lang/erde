-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Block.parse', function()
  spec('rule', function()
    assert.are.equal('Block', parse.Block('').rule)
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
