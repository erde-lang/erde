local unit = require('erde.parser.unit')

spec('params rule', function()
  assert.are.equal('Params', unit.Params('()').rule)
end)

spec('params', function()
  assert.are.equal(0, #unit.Params('()'))
  assert.has_subtable({
    { value = { value = 'a' } },
  }, unit.Params('(a)'))
  assert.has_subtable({
    { value = { value = 'a' } },
    { value = { value = 'b' } },
  }, unit.Params(
    '(a, b)'
  ))
  assert.has_subtable({
    { value = { rule = 'Destructure' } },
  }, unit.Params(
    '({ :a })'
  ))
end)

spec('optional params', function()
  assert.has_subtable({
    {
      default = { value = '2' },
      value = { value = 'a' },
    },
  }, unit.Params(
    '(a = 2)'
  ))
end)

spec('params varargs', function()
  assert.has_subtable({
    { varargs = true },
  }, unit.Params('(...)'))
  assert.has_subtable({
    { value = { value = 'a' } },
    { varargs = true },
  }, unit.Params(
    '(a, ...)'
  ))
  assert.has_subtable({
    { value = { value = 'a' } },
    { varargs = true, name = 'b' },
  }, unit.Params(
    '(a, ...b)'
  ))
  assert.has_error(function()
    unit.Params('(..., a)')
  end)
end)
