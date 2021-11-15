-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Table.parse', function()
  spec('ruleName', function()
    assert.are.equal('Table', parse.Table('{}').ruleName)
  end)

  spec('table arrayKey', function()
    assert.has_subtable({
      {
        variant = 'arrayKey',
        key = 1,
        value = { value = '10' },
      },
    }, parse.Table(
      '{ 10 }'
    ))
  end)

  spec('table inlineKey', function()
    assert.has_subtable({
      {
        variant = 'inlineKey',
        key = 'x',
      },
    }, parse.Table(
      '{ :x }'
    ))
  end)

  spec('table nameKey', function()
    assert.has_subtable({
      {
        variant = 'nameKey',
        key = 'x',
        value = { value = '2' },
      },
    }, parse.Table(
      '{ x: 2 }'
    ))
  end)

  spec('table stringKey', function()
    assert.has_subtable({
      {
        variant = 'stringKey',
        key = { ruleName = 'String', variant = 'short' },
        value = { value = '3' },
      },
    }, parse.Table(
      "{ 'my-key': 3 }"
    ))
    assert.has_subtable({
      {
        variant = 'stringKey',
        key = { ruleName = 'String', variant = 'short' },
        value = { value = '3' },
      },
    }, parse.Table(
      '{ "my-key": 3 }'
    ))
    assert.has_subtable({
      {
        variant = 'stringKey',
        key = { ruleName = 'String', variant = 'long' },
        value = { value = '3' },
      },
    }, parse.Table(
      '{ `my-key`: 3 }'
    ))
  end)

  spec('table exprKey', function()
    assert.has_subtable({
      {
        variant = 'exprKey',
        key = { op = { tag = 'add' } },
        value = { value = '3' },
      },
    }, parse.Table(
      '{ [1 + 2]: 3 }'
    ))
    assert.has_error(function()
      parse.Table('{ [1 + 2] }')
    end)
  end)

  spec('table mixed variants', function()
    assert.has_subtable({
      { key = 1 },
      { key = 'b' },
      { key = 2 },
      { key = 'd' },
      { key = { variant = 'short' } },
      { key = { variant = 'long' } },
    }, parse.Table(
      '{ a, :b, c, d: 1, "e": 3, [`f`]: 2 }'
    ))
  end)

  spec('nested table', function()
    assert.has_subtable({
      {
        key = 'x',
        value = {
          { key = 'y', value = { value = '1' } },
        },
      },
    }, parse.Table(
      '{ x: { y: 1 } }'
    ))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Table.compile', function()
  spec('table arrayKey', function()
    assert.eval({ 10 }, compile.Table('{ 10 }'))
  end)

  spec('table inlineKey', function()
    assert.run(
      { x = 1 },
      compile.Block([[
        local x = 1
        return { :x }
      ]])
    )
  end)

  spec('table nameKey', function()
    assert.eval({ x = 2 }, compile.Table('{ x: 2 }'))
  end)

  spec('table stringKey', function()
    assert.eval({ ['my-key'] = 3 }, compile.Table("{'my-key': 3}"))
    assert.eval({ ['my-key'] = 3 }, compile.Table('{"my-key": 3}'))
    assert.eval({ ['my-key'] = 3 }, compile.Table('{`my-key`: 3}'))
  end)

  spec('table exprKey', function()
    assert.eval({ [3] = 1 }, compile.Table('{ [1 + 2]: 1 }'))
  end)

  spec('nested table', function()
    assert.eval({ x = { y = 1 } }, compile.Table('{ x: { y: 1 } }'))
  end)
end)
