local unit = require('erde.parser.unit')

spec('table rule', function()
  assert.has_subtable({ rule = 'Table' }, unit.Table('{}'))
end)

spec('table field variants', function()
  assert.has_subtable({
    {
      variant = 'array',
      key = 1,
      value = { value = '10' },
    },
  }, unit.Table(
    '{ 10 }'
  ))
  assert.has_subtable({
    {
      variant = 'inlineKey',
      key = 'x',
    },
  }, unit.Table(
    '{ :x }'
  ))
  assert.has_subtable({
    {
      variant = 'nameKey',
      key = 'x',
      value = { value = '2' },
    },
  }, unit.Table(
    '{ x: 2 }'
  ))
  assert.has_subtable({
    {
      variant = 'stringKey',
      key = { rule = 'String' },
      value = { value = '3' },
    },
  }, unit.Table(
    '{ "my-key": 3 }'
  ))
  assert.has_subtable({
    {
      variant = 'exprKey',
      key = { op = 'add' },
      value = { value = '3' },
    },
  }, unit.Table(
    '{ [1 + 2]: 3 }'
  ))
end)

spec('valid table', function()
  assert.has_subtable({ rule = 'Table' }, unit.Table('{}'))
  assert.has_subtable({
    { key = 'x', value = { value = '2' } },
    { key = 1, value = { value = '10' } },
    { key = 'y', value = { value = '1' } },
    { key = 2, value = { value = '20' } },
  }, unit.Table(
    '{ x: 2, 10, y: 1, 20 }'
  ))
  assert.has_subtable({
    {
      key = 'x',
      value = {
        { key = 'y', value = { value = '1' } },
      },
    },
  }, unit.Table(
    '{ x: { y: 1 } }'
  ))
end)

spec('invalid table', function()
  assert.has_error(function()
    unit.Table('{ x: }')
  end)
  assert.has_error(function()
    unit.Table('{ []: 1 }')
  end)
  assert.has_error(function()
    unit.Table('{ : 1 }')
  end)
  assert.has_error(function()
    unit.Table('{ x: 1')
  end)
  assert.has_error(function()
    unit.Table('{ x: 1 y: 2 }')
  end)
end)
