local unit = require('erde.parser.unit')

spec('valid destructure', function()
  assert.has_subtable({
    tag = TAG_DESTRUCTURE,
    { key = 1, name = 'x' },
    { key = 2, name = 'y' },
  }, unit.Destructure(
    '{ x, y }'
  ))
  assert.has_subtable({
    tag = TAG_DESTRUCTURE,
    { key = 'x', name = 'x' },
    { key = 1, name = 'y' },
  }, unit.Destructure(
    '{ :x, y }'
  ))
  assert.has_subtable({
    tag = TAG_DESTRUCTURE,
    { key = 1, name = 'x' },
    {
      key = 'y',
      name = 'y',
      destructure = {
        { key = 1, name = 'z' },
      },
    },
  }, unit.Destructure(
    '{ x, :y { z } }'
  ))
  assert.has_subtable({
    tag = TAG_DESTRUCTURE,
    optional = true,
    {
      key = 1,
      destructure = {
        optional = true,
        { key = 1, name = 'z' },
      },
    },
  }, unit.Destructure(
    '?{ ?{ z } }'
  ))
end)

spec('invalid short comment', function()
  assert.has_error(function()
    unit.Comment('')
  end)
end)
