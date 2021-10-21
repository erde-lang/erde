local unit = require('erde.parser.unit')

spec('valid id', function()
  assert.has_subtable({
    tag = 'TAG_PARAMS',
    { tag = 'TAG_PARAM', value = { value = 'a' } },
  }, unit.Params(
    '(a)'
  ))
end)
