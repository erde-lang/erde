-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Destructure.parse', function()
  spec('rule', function()
    assert.are.equal('Destructure', parse.Destructure('{}').rule)
  end)

  spec('destructure mapDestruct', function()
    assert.has_subtable({
      { name = 'a' },
    }, parse.Destructure(
      '{ :a }'
    ))
    assert.has_error(function()
      parse.Destructure('{ : }')
    end)
  end)

  spec('destructure arrayDestruct', function()
    assert.has_subtable({
      { key = 1, name = 'a' },
      { key = 2, name = 'b' },
    }, parse.Destructure(
      '{ a, b }'
    ))
  end)

  spec('destructure mixed', function()
    assert.has_subtable({
      { key = 1, name = 'a' },
      { name = 'b' },
      { key = 2, name = 'c' },
    }, parse.Destructure(
      '{ a, :b, c }'
    ))
  end)

  spec('optional destructure', function()
    assert.has_subtable({
      optional = true,
      { name = 'a' },
    }, parse.Destructure(
      '?{ :a }'
    ))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Destructure.compile', function()
  spec('sanity check', function()
    assert.is_not_nil(compile.Destructure('{}').baseName)
    assert.is_not_nil(compile.Destructure('{}').compiled)
  end)
end)
