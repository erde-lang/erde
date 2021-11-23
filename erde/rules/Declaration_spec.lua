-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Declaration.parse', function()
  spec('local declaration', function()
    assert.has_subtable({
      variant = 'local',
      varList = { { value = 'abc' } },
    }, parse.Declaration(
      'local abc'
    ))
    assert.has_subtable({
      variant = 'local',
      varList = { { value = 'abc' } },
      exprList = { { value = '2' } },
    }, parse.Declaration(
      'local abc = 2'
    ))
  end)

  spec('module declaration', function()
    assert.has_subtable({
      variant = 'module',
      varList = { { value = 'abc' } },
    }, parse.Declaration(
      'module abc'
    ))
    assert.has_subtable({
      variant = 'module',
      varList = { { value = 'abc' } },
      exprList = { { value = '2' } },
    }, parse.Declaration(
      'module abc = 2'
    ))
  end)

  spec('global declaration', function()
    assert.has_subtable({
      variant = 'global',
      varList = { { value = 'abc' } },
    }, parse.Declaration(
      'global abc'
    ))
    assert.has_subtable({
      variant = 'global',
      varList = { { value = 'abc' } },
      exprList = { { value = '2' } },
    }, parse.Declaration(
      'global abc = 2'
    ))
  end)

  spec('multiple declaration', function()
    assert.has_subtable({
      varList = {
        { value = 'a' },
        { value = 'b' },
      },
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

  spec('destructure declaration', function()
    assert.has_subtable({
      variant = 'local',
      varList = { { ruleName = 'Destructure' } },
    }, parse.Declaration(
      'local { a } = x'
    ))
    assert.has_subtable({
      variant = 'local',
      varList = {
        { value = 'a' },
        { ruleName = 'Destructure' },
        { value = 'c' },
      },
    }, parse.Declaration(
      'local a, { b }, c = x'
    ))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Declaration.compile', function()
  spec('local declaration', function()
    assert.run(
      1,
      compile.Block([[
        local a = 1
        return a
      ]])
    )
  end)

  spec('module declaration', function()
    assert.run(
      { a = 1 },
      compile.Block('module a = 1', { isModuleBlock = true })
    )
  end)

  spec('global declaration', function()
    assert.run(
      1,
      compile.Block([[
        global a = 1
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
