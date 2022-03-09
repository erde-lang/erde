-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Declaration.parse', function()
  spec('local declaration', function()
    assert.subtable({
      variant = 'local',
      varList = { 'abc' },
    }, parse.Declaration('local abc'))
    assert.subtable({
      variant = 'local',
      varList = { 'abc' },
      exprList = { '2' },
    }, parse.Declaration('local abc = 2'))
  end)

  spec('global declaration', function()
    assert.subtable({
      variant = 'global',
      varList = { 'abc' },
    }, parse.Declaration('global abc'))
    assert.subtable({
      variant = 'global',
      varList = { 'abc' },
      exprList = { '2' },
    }, parse.Declaration('global abc = 2'))
  end)

  spec('module declaration', function()
    assert.subtable({
      {
        variant = 'module',
        varList = { 'abc' },
      },
    }, parse.Module('module abc'))
    assert.subtable({
      {
        variant = 'module',
        varList = { 'abc' },
        exprList = { '2' },
      },
    }, parse.Module('module abc = 2'))
    assert.has_error(function()
      parse.Declaration('if true { module abc }')
    end)
  end)

  spec('main declaration', function()
    assert.subtable({
      {
        variant = 'main',
        varList = { 'abc' },
      },
    }, parse.Module('main abc'))
    assert.subtable({
      {
        variant = 'main',
        varList = { 'abc' },
        exprList = { '2' },
      },
    }, parse.Module('main abc = 2'))
    assert.has_error(function()
      parse.Declaration('if true { main abc }')
    end)
    assert.has_error(function()
      parse.Declaration('main a, b')
    end)
    assert.has_error(function()
      parse.Declaration('main { a, b } = c')
    end)
  end)

  spec('multiple declaration', function()
    assert.subtable({
      varList = {
        'a',
        'b',
      },
    }, parse.Declaration('local a, b'))
    assert.subtable({
      exprList = {
        '1',
        '2',
      },
    }, parse.Declaration('local a, b = 1, 2'))
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
    }, parse.Declaration('local { a } = x'))
    assert.subtable({
      variant = 'local',
      varList = {
        'a',
        { ruleName = 'Destructure' },
        'c',
      },
    }, parse.Declaration('local a, { b }, c = x, y'))
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

  spec('global declaration', function()
    assert.run(
      1,
      compile.Block([[
        global a = 1
        return a
      ]])
    )
  end)

  spec('module declaration', function()
    assert.run({ a = 1 }, compile.Module('module a = 1'))
  end)

  spec('main declaration', function()
    assert.run(1, compile.Module('main a = 1'))
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
