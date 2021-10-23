local unit = require('erde.parser.unit')

spec('valid repeat until', function()
  assert.has_subtable({
    rule = 'RepeatUntil',
    cond = {
      op = 'gt',
      { value = '1' },
      { value = '0' },
    },
  }, unit.RepeatUntil(
    'repeat {} until (1 > 0)'
  ))
end)

spec('invalid repeat until', function()
  assert.has_error(function()
    unit.RepeatUntil('repeat {} until 1 > 0')
  end)
  assert.has_error(function()
    unit.RepeatUntil('repeat until 1 > 0')
  end)
  assert.has_error(function()
    unit.RepeatUntil('repeat {} until ()')
  end)
  assert.has_error(function()
    unit.RepeatUntil('repeat {}')
  end)
end)
