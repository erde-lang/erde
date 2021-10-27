local unit = require('erde.parser.unit')

spec('valid id', function()
  assert.has_subtable({
    base = { value = 'a' },
  }, unit.Id('a'))
  assert.has_subtable({
    base = { value = 'a' },
    { optional = false, variant = 'dot', value = 'b' },
  }, unit.Id(
    'a.b'
  ))
  assert.has_subtable({
    base = { value = 'a' },
    {
      optional = false,
      variant = 'bracket',
      value = {
        value = '23',
      },
    },
  }, unit.Id(
    'a[23]'
  ))
  assert.has_subtable({
    base = { value = 'a' },
    {
      optional = false,
      variant = 'bracket',
      value = { op = { tag = 'add' } },
    },
  }, unit.Id(
    'a[2 + 3]'
  ))
  assert.has_subtable({
    base = { value = 'a' },
    { optional = true, variant = 'dot', value = 'b' },
  }, unit.Id(
    'a?.b'
  ))
  assert.has_subtable({
    base = { op = { tag = 'add' }, parens = true },
    { optional = false, variant = 'dot', value = 'b' },
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
