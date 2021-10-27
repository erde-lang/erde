local unit = require('erde.parser.unit')

spec('destructure rule', function()
  assert.are.equal('Destructure', unit.Destructure('{}').rule)
end)

spec('destructure mapDestruct', function()
  assert.has_subtable({
    { name = 'a' },
  }, unit.Destructure('{ :a }'))
  assert.has_error(function()
    unit.Destructure('{ : }')
  end)
end)

spec('destructure arrayDestruct', function()
  assert.has_subtable({
    { key = 1, name = 'a' },
    { key = 2, name = 'b' },
  }, unit.Destructure(
    '{ a, b }'
  ))
end)

spec('destructure mixed', function()
  assert.has_subtable({
    { key = 1, name = 'a' },
    { name = 'b' },
    { key = 2, name = 'c' },
  }, unit.Destructure(
    '{ a, :b, c }'
  ))
end)

spec('nested destructure', function()
  assert.has_subtable({
    {
      name = 'a',
      destructure = {
        { key = 1, name = 'b' },
      },
    },
  }, unit.Destructure(
    '{ :a { b } }'
  ))
  assert.has_subtable({
    {
      destructure = {
        { key = 1, name = 'a' },
      },
    },
  }, unit.Destructure(
    '{ { a } }'
  ))
  assert.has_error(function()
    unit.Destructure('{ a { b } }')
  end)
end)

spec('optional destructure', function()
  assert.has_subtable({
    optional = true,
    { name = 'a' },
  }, unit.Destructure(
    '?{ :a }'
  ))
end)
