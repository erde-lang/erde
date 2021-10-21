local unit = require('erde.parser.unit')

spec('valid params', function()
  assert.has_subtable({
    tag = 'TAG_PARAMS',
  }, unit.Params('()'))
  assert.has_subtable({
    tag = 'TAG_PARAMS',
    { tag = 'TAG_PARAM', value = { value = 'a' } },
  }, unit.Params(
    '(a)'
  ))
  assert.has_subtable({
    tag = 'TAG_PARAMS',
    { tag = 'TAG_PARAM', value = { value = 'a' } },
    { tag = 'TAG_PARAM', value = { value = 'b' } },
  }, unit.Params(
    '(a, b)'
  ))
  assert.has_subtable({
    tag = 'TAG_PARAMS',
    {
      tag = 'TAG_PARAM',
      default = { value = '2' },
      value = { value = 'a' },
    },
  }, unit.Params(
    '(a = 2)'
  ))
  assert.has_subtable({
    tag = 'TAG_PARAMS',
    { tag = 'TAG_VARARGS' },
  }, unit.Params(
    '(...)'
  ))
  assert.has_subtable({
    tag = 'TAG_PARAMS',
    { tag = 'TAG_PARAM', value = { value = 'a' } },
    { tag = 'TAG_VARARGS' },
  }, unit.Params(
    '(a, ...)'
  ))
  assert.has_subtable({
    tag = 'TAG_PARAMS',
    { tag = 'TAG_PARAM', value = { value = 'a' } },
    { tag = 'TAG_VARARGS', name = 'b' },
  }, unit.Params(
    '(a, ...b)'
  ))
  assert.has_subtable({
    tag = 'TAG_PARAMS',
    { tag = 'TAG_PARAM', value = { tag = 'TAG_DESTRUCTURE' } },
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
