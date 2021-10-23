local unit = require('erde.parser.unit')

spec('valid params', function()
  assert.has_subtable({
    rule = 'Params',
  }, unit.Params('()'))
  assert.has_subtable({
    rule = 'Params',
    { value = { value = 'a' } },
  }, unit.Params(
    '(a)'
  ))
  assert.has_subtable({
    rule = 'Params',
    { value = { value = 'a' } },
    { value = { value = 'b' } },
  }, unit.Params(
    '(a, b)'
  ))
  assert.has_subtable({
    rule = 'Params',
    {
      default = { value = '2' },
      value = { value = 'a' },
    },
  }, unit.Params(
    '(a = 2)'
  ))
  assert.has_subtable({
    rule = 'Params',
    { varargs = true },
  }, unit.Params(
    '(...)'
  ))
  assert.has_subtable({
    rule = 'Params',
    { value = { value = 'a' } },
    { varargs = true },
  }, unit.Params(
    '(a, ...)'
  ))
  assert.has_subtable({
    rule = 'Params',
    { value = { value = 'a' } },
    { varargs = true, name = 'b' },
  }, unit.Params(
    '(a, ...b)'
  ))
  assert.has_subtable({
    rule = 'Params',
    { value = { rule = 'Destructure' } },
  }, unit.Params(
    '({ :a })'
  ))
end)

spec('invalid params', function()
  assert.has_error(function()
    unit.Params('(..., a)')
  end)
  assert.has_error(function()
    unit.Params('(a b)')
  end)
end)
