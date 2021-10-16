local unit = require('erde.parser.unit')

spec('valid numeric for', function()
  assert.has_subtable({
    tag = 'TAG_NUMERIC_FOR',
    name = 'i',
    var = { value = '1' },
    limit = { value = '2' },
    step = { value = '3' },
  }, unit.ForLoop(
    'for i = 1, 2, 3 {}'
  ))
  assert.has_subtable({
    tag = 'TAG_NUMERIC_FOR',
    name = 'i',
    var = { value = '1' },
    limit = { value = '2' },
  }, unit.ForLoop(
    'for i = 1, 2 {}'
  ))
end)

spec('invalid numeric for', function()
  assert.has_error(function()
    unit.ForLoop('for i = 1 {}')
  end)
  assert.has_error(function()
    unit.ForLoop('for i = 1, 2, {}')
  end)
  assert.has_error(function()
    unit.ForLoop('for i = 1, 2, 3, 4 {}')
  end)
  assert.has_error(function()
    unit.ForLoop('for i = 1, 2')
  end)
end)

spec('valid generic for', function()
  assert.has_subtable({
    tag = 'TAG_GENERIC_FOR',
    nameList = { 'a' },
    exprList = { { value = '1' } },
  }, unit.ForLoop(
    'for a in 1 {}'
  ))
  assert.has_subtable({
    tag = 'TAG_GENERIC_FOR',
    nameList = { 'a', 'b' },
    exprList = { { value = '1' } },
  }, unit.ForLoop(
    'for a, b in 1 {}'
  ))
  assert.has_subtable({
    tag = 'TAG_GENERIC_FOR',
    nameList = { 'a' },
    exprList = {
      { value = '1' },
      { value = '2' },
    },
  }, unit.ForLoop(
    'for a in 1, 2 {}'
  ))
  assert.has_subtable({
    tag = 'TAG_GENERIC_FOR',
    nameList = { 'a', 'b' },
    exprList = {
      { value = '1' },
      { value = '2' },
    },
  }, unit.ForLoop(
    'for a, b in 1, 2 {}'
  ))
end)

spec('invalid generic for', function()
  assert.has_error(function()
    unit.ForLoop('for a 1 {}')
  end)
  assert.has_error(function()
    unit.ForLoop('for a in {}')
  end)
  assert.has_error(function()
    unit.ForLoop('for in 1 {}')
  end)
  assert.has_error(function()
    unit.ForLoop('for a in 1')
  end)
end)
