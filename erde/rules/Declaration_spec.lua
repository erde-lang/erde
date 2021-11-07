-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Declaration.parse', function()
  spec('rule', function()
    assert.are.equal('Declaration', parse.Declaration('local a').rule)
  end)

  spec('local declaration', function()
    assert.has_subtable({
      variant = 'local',
      nameList = { 'abc' },
    }, parse.Declaration(
      'local abc'
    ))
    assert.has_subtable({
      variant = 'local',
      nameList = { 'abc' },
      exprList = { { value = '2' } },
    }, parse.Declaration(
      'local abc = 2'
    ))
  end)

  spec('global declaration', function()
    assert.has_subtable({
      variant = 'global',
      nameList = { 'abc' },
    }, parse.Declaration(
      'global abc'
    ))
    assert.has_subtable({
      variant = 'global',
      nameList = { 'abc' },
      exprList = { { value = '2' } },
    }, parse.Declaration(
      'global abc = 2'
    ))
  end)

  spec('multiple declaration', function()
    assert.has_subtable({
      nameList = { 'a', 'b' },
    }, parse.Declaration(
      'local a, b'
    ))
    assert.has_subtable({
      exprList = {
        { value = '1' },
        { value = '2' },
      },
    }, parse.Declaration(
      'local a, b = 1, 2'
    ))
    assert.has_error(function()
      parse.Declaration('local a,')
    end)
    assert.has_error(function()
      parse.Declaration('local a = 1,')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Declaration.compile', function()
  spec('declaration', function()
    assert.run(
      1,
      compile.Block([[
        local a = 1
        return a
      ]])
    )
  end)

  spec('multiple declaration', function()
    assert.run(
      3,
      compile.Block([[
        local a, b = 1, 2
        return a + b
      ]])
    )
  end)
end)
