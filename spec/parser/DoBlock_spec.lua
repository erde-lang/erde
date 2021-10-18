local unit = require('erde.parser.unit')

spec('valid do block', function()
  assert.has_subtable({
    tag = 'TAG_DO_BLOCK',
  }, unit.DoBlock('do {}'))
  assert.has_subtable({
    tag = 'TAG_DO_BLOCK',
    hasReturn = true,
  }, unit.DoBlock(
    'do { return 1 }'
  ))
end)

spec('invalid do block', function()
  assert.has_error(function()
    unit.DoBlock('do')
  end)
  assert.has_error(function()
    unit.DoBlock('do {')
  end)
end)
