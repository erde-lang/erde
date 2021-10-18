local unit = require('erde.parser.unit')

spec('valid while loop', function()
  assert.has_subtable({
    tag = 'TAG_WHILE_LOOP',
    cond = {
      tag = 'TAG_GT',
      { value = '1' },
      { value = '0' },
    },
  }, unit.WhileLoop(
    'while 1 > 0 {}'
  ))
end)

spec('invalid while loop', function()
  assert.has_error(function()
    unit.WhileLoop('while {}')
  end)
  assert.has_error(function()
    unit.WhileLoop('while 1 > 0')
  end)
  assert.has_error(function()
    unit.WhileLoop('while 1 > 0 {')
  end)
  assert.has_error(function()
    unit.WhileLoop('wihle 1 > 0 {}')
  end)
end)
