local unit = require('erde.parser.unit')

spec('valid table', function()
  assert.has_subtable({
    tag = 'TAG_TABLE',
    { key = 'x', value = 'x' },
  }, unit.Table(
    '{ :x }'
  ))
  assert.has_subtable({
    tag = 'TAG_TABLE',
    { key = 1, value = { value = '10' } },
  }, unit.Table(
    '{ 10 }'
  ))
  assert.has_subtable({
    tag = 'TAG_TABLE',
    { key = 'x', value = { value = '2' } },
  }, unit.Table(
    '{ x: 2 }'
  ))
  assert.has_subtable({
    tag = 'TAG_TABLE',
    {
      key = { tag = TAG_SHORT_STRING },
      value = { value = '3' },
    },
  }, unit.Table(
    '{ "my-key": 3 }'
  ))
  assert.has_subtable({
    tag = 'TAG_TABLE',
    {
      key = { tag = TAG_ADD },
      value = { value = '3' },
    },
  }, unit.Table(
    '{ [1 + 2]: 3 }'
  ))
  assert.has_subtable({
    tag = 'TAG_TABLE',
    { key = 'x', value = { value = '2' } },
    { key = 1, value = { value = '10' } },
    { key = 'y', value = { value = '1' } },
    { key = 2, value = { value = '20' } },
  }, unit.Table(
    '{ x: 2, 10, y: 1, 20 }'
  ))
  assert.has_subtable({
    tag = 'TAG_TABLE',
    {
      key = 'x',
      value = {
        tag = 'TAG_TABLE',
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
