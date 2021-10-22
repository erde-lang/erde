local unit = require('erde.parser.unit')

spec('valid arrow function', function()
  assert.has_subtable({
    tag = 'TAG_ARROW_FUNCTION',
    variant = 'SKINNY',
    body = {
      { tag = 'TAG_RETURN' },
    },
  }, unit.ArrowFunction(
    '() -> { return 1 }'
  ))
  assert.has_subtable({
    tag = 'TAG_ARROW_FUNCTION',
    variant = 'SKINNY',
    returns = {
      { value = '1' },
    },
  }, unit.ArrowFunction(
    '() -> 1'
  ))
  assert.has_subtable({
    tag = 'TAG_ARROW_FUNCTION',
    variant = 'SKINNY',
    returns = {
      { value = '1' },
      { value = '2' },
    },
  }, unit.ArrowFunction(
    '() -> 1, 2'
  ))
  assert.has_subtable({
    tag = 'TAG_ARROW_FUNCTION',
    variant = 'FAT',
  }, unit.ArrowFunction(
    '() => { return 1 }'
  ))
end)

spec('invalid arrow function', function()
  assert.has_error(function()
    unit.ArrowFunction('-> {}')
  end)
  assert.has_error(function()
    unit.ArrowFunction('() ~> {}')
  end)
  assert.has_error(function()
    unit.ArrowFunction('() ~> 1,')
  end)
  assert.has_error(function()
    unit.ArrowFunction('() ~> ,1')
  end)
end)
