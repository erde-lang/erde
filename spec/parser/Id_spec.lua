local unit = require('erde.parser.unit')

spec('valid id', function()
  assert.has_subtable({
    tag = 'TAG_ID',
    base = { value = 'a' },
  }, unit.Id(
    'a'
  ))
  assert.has_subtable({
    tag = 'TAG_ID',
    base = { value = 'a' },
    { optional = false, variant = 'DOT_INDEX', value = 'b' },
  }, unit.Id(
    'a.b'
  ))
  assert.has_subtable({
    tag = 'TAG_ID',
    base = { value = 'a' },
    {
      optional = false,
      variant = 'BRACKET_INDEX',
      value = {
        value = '23',
      },
    },
  }, unit.Id(
    'a[23]'
  ))
  assert.has_subtable({
    tag = 'TAG_ID',
    base = { value = 'a' },
    {
      optional = false,
      variant = 'BRACKET_INDEX',
      value = { tag = 'TAG_ADD' },
    },
  }, unit.Id(
    'a[2 + 3]'
  ))
  assert.has_subtable({
    tag = 'TAG_ID',
    base = { value = 'a' },
    { optional = true, variant = 'DOT_INDEX', value = 'b' },
  }, unit.Id(
    'a?.b'
  ))
  assert.has_subtable({
    tag = 'TAG_ID',
    base = { tag = 'TAG_ADD', parens = true },
    { optional = false, variant = 'DOT_INDEX', value = 'b' },
  }, unit.Id(
    '(1 + 2).b'
  ))
end)

spec('invalid id', function()
  assert.has_error(function()
    unit.Id('a.b()')
  end)
  assert.has_error(function()
    unit.Id('a:b')
  end)
  assert.has_error(function()
    unit.Id('1.b')
  end)
  assert.has_error(function()
    unit.Id('a.[b]')
  end)
  assert.has_error(function()
    unit.Id('a[b')
  end)
end)
