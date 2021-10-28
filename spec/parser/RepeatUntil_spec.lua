local unit = require('erde.parser.unit')

spec('repeat until rule', function()
  assert.are.equal(
    'RepeatUntil',
    unit.RepeatUntil('repeat {} until (true)').rule
  )
end)

spec('repeat until', function()
  assert.has_subtable({
    cond = { value = 'true' },
  }, unit.RepeatUntil(
    'repeat {} until (true)'
  ))
  assert.has_error(function()
    unit.RepeatUntil('repeat {} until true')
  end)
  assert.has_error(function()
    unit.RepeatUntil('repeat {} until ()')
  end)
end)
