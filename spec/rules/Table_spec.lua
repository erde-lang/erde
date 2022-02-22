-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Table.parse', function()
  spec('table numberKey', function()
    assert.subtable({
      {
        variant = 'numberKey',
        value = { value = '10' },
      },
    }, parse.Table('{ 10 }'))
  end)

  spec('table nameKey', function()
    assert.subtable({
      {
        variant = 'nameKey',
        key = { value = 'x' },
        value = { value = '2' },
      },
    }, parse.Table('{ x = 2 }'))
  end)

  spec('table exprKey', function()
    assert.subtable({
      {
        variant = 'exprKey',
        key = { op = { token = '+' } },
        value = { value = '3' },
      },
    }, parse.Table('{ [1 + 2] = 3 }'))
    assert.has_error(function()
      parse.Table('{ [1 + 2] }')
    end)
  end)

  spec('table mixed variants', function()
    assert.subtable({
      { value = { value = 'a' } },
      { value = { value = 'b' } },
      { key = { value = 'c' } },
      { key = { variant = 'long' } },
    }, parse.Table('{ a, b, c = 1, [ [[d]] ] = 2 }'))
  end)

  spec('nested table', function()
    assert.subtable({
      {
        key = { value = 'x' },
        value = {
          { key = { value = 'y' }, value = { value = '1' } },
        },
      },
    }, parse.Table('{ x = { y = 1 } }'))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Table.compile', function()
  spec('table numberKey', function()
    assert.eval({ 10 }, compile.Table('{ 10 }'))
  end)

  spec('table nameKey', function()
    assert.eval({ x = 2 }, compile.Table('{ x = 2 }'))
  end)

  spec('table exprKey', function()
    assert.eval({ [3] = 1 }, compile.Table('{ [1 + 2] = 1 }'))
  end)

  spec('nested table', function()
    assert.eval({ x = { y = 1 } }, compile.Table('{ x = { y = 1 } }'))
  end)
end)
