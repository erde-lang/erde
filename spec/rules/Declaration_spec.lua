-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Declaration.parse', function()
  spec('local declaration', function()
    assert.subtable({
      variant = 'local',
      varList = { 'abc' },
    }, parse.Declaration(
      'local abc'
    ))
    assert.subtable({
      variant = 'local',
      varList = { 'abc' },
      exprList = { { value = '2' } },
    }, parse.Declaration(
      'local abc = 2'
    ))
  end)

  spec('module declaration', function()
    assert.subtable({
      {
        variant = 'module',
        varList = { 'abc' },
      },
    }, parse.Block(
      'module abc'
    ))
    assert.subtable({
      {
        variant = 'module',
        varList = { 'abc' },
        exprList = { { value = '2' } },
      },
    }, parse.Block(
      'module abc = 2'
    ))
  end)

  spec('global declaration', function()
    assert.subtable({
      variant = 'global',
      varList = { 'abc' },
    }, parse.Declaration(
      'global abc'
    ))
    assert.subtable({
      variant = 'global',
      varList = { 'abc' },
      exprList = { { value = '2' } },
    }, parse.Declaration(
      'global abc = 2'
    ))
  end)

  spec('multiple declaration', function()
    assert.subtable({
      varList = {
        'a',
        'b',
      },
    }, parse.Declaration(
      'local a, b'
    ))
    assert.subtable({
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
    assert.subtable({
      variant = 'local',
      varList = { { ruleName = 'Destructure' } },
    }, parse.Declaration(
      'local { a } = x'
    ))
    assert.subtable({
      variant = 'local',
      varList = {
        'a',
        { ruleName = 'Destructure' },
        'c',
      },
    }, parse.Declaration(
      'local a, { b }, c = x, y'
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
    assert.run({ a = 1 }, compile.Block('module a = 1'))
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

  spec('destructure declaration', function()
    assert.run(
      1,
      compile.Block([[
        local a = { x = 1 }
        local { x } = a
        return x
      ]])
    )
  end)
end)
