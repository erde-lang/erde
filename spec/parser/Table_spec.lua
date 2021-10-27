local unit = require('erde.parser.unit')

spec('table rule', function()
  assert.are.equal('Table', unit.Table('{}').rule)
end)

spec('table arrayKey', function()
  assert.has_subtable({
    {
      variant = 'arrayKey',
      key = 1,
      value = { value = '10' },
    },
  }, unit.Table(
    '{ 10 }'
  ))
  assert.has_subtable({
    {
      variant = 'arrayKey',
      key = 1,
      value = { value = '10' },
    },
    {
      variant = 'arrayKey',
      key = 2,
      value = { value = '20' },
    },
  }, unit.Table(
    '{ 10, 20 }'
  ))
end)

spec('table inlineKey', function()
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
      variant = 'inlineKey',
      key = 'x',
    },
    {
      variant = 'inlineKey',
      key = 'h1',
    },
  }, unit.Table(
    '{ :x, :h1 }'
  ))
end)

spec('table nameKey', function()
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
      variant = 'nameKey',
      key = 'h1',
      value = { value = '2' },
    },
  }, unit.Table(
    '{ h1: 2 }'
  ))
end)

spec('table stringKey', function()
  assert.has_subtable({
    {
      variant = 'stringKey',
      key = { rule = 'String', variant = 'short' },
      value = { value = '3' },
    },
  }, unit.Table(
    "{ 'my-key': 3 }"
  ))
  assert.has_subtable({
    {
      variant = 'stringKey',
      key = { rule = 'String', variant = 'short' },
      value = { value = '3' },
    },
  }, unit.Table(
    '{ "my-key": 3 }'
  ))
  assert.has_subtable({
    {
      variant = 'stringKey',
      key = { rule = 'String', variant = 'long' },
      value = { value = '3' },
    },
  }, unit.Table(
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
  }, unit.Table(
    '{ [1 + 2]: 3 }'
  ))
  assert.has_error(function()
    unit.Table('{ [1 + 2] }')
  end)
end)

spec('nested table', function()
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
