local unit = require('erde.parser.unit')

spec('valid do block', function()
  assert.has_subtable({
    tag = 'TAG_DO_BLOCK',
  }, unit.doBlock('do {}'))
  assert.has_subtable({
    tag = 'TAG_DO_BLOCK',
    hasReturn = true,
  }, unit.doBlock(
    'do { return 1 }'
  ))
end)

spec('invalid do block', function()
  assert.has_error(function()
    unit.doBlock('do')
  end)
  assert.has_error(function()
    unit.doBlock('do {')
  end)
end)
