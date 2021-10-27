local unit = require('erde.parser.unit')

spec('do block rule', function()
  assert.are.equal('DoBlock', unit.DoBlock('do {}').rule)
end)

spec('do block', function()
  assert.has_subtable({
    body = {
      { rule = 'Assignment' },
    },
  }, unit.DoBlock(
    'do { x = 3 }'
  ))
end)

spec('do block return ', function()
  assert.has_subtable({
    hasReturn = true,
  }, unit.DoBlock(
    'do { return 1 }'
  ))
end)
