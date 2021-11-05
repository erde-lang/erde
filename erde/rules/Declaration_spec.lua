-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Declaration.parse', function()
  spec('rule', function()
    assert.are.equal('Declaration', unit.Declaration('local a').rule)
  end)

  spec('local declaration', function()
    assert.has_subtable({
      variant = 'local',
      nameList = { 'abc' },
    }, unit.Declaration(
      'local abc'
    ))
    assert.has_subtable({
      variant = 'local',
      nameList = { 'abc' },
      exprList = { { value = '2' } },
    }, unit.Declaration(
      'local abc = 2'
    ))
  end)

  spec('global declaration', function()
    assert.has_subtable({
      variant = 'global',
      nameList = { 'abc' },
    }, unit.Declaration(
      'global abc'
    ))
    assert.has_subtable({
      variant = 'global',
      nameList = { 'abc' },
      exprList = { { value = '2' } },
    }, unit.Declaration(
      'global abc = 2'
    ))
  end)

  spec('multiple declaration', function()
    assert.has_subtable({
      nameList = { 'a', 'b' },
    }, unit.Declaration(
      'local a, b'
    ))
    assert.has_subtable({
      exprList = {
        { value = '1' },
        { value = '2' },
      },
    }, unit.Declaration(
      'local a, b = 1, 2'
    ))
    assert.has_error(function()
      unit.Declaration('local a,')
    end)
    assert.has_error(function()
      unit.Declaration('local a = 1,')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Declaration.compile', function()
  -- TODO
end)
