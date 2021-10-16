local unit = require('erde.parser.unit')

spec('valid while loop', function()
  assert.has_subtable({
    tag = 'TAG_WHILE_LOOP',
    cond = {
      tag = 'TAG_GT',
      { value = '1' },
      { value = '0' },
    },
  }, unit.whileLoop(
    'while 1 > 0 {}'
  ))
end)

spec('invalid while loop', function()
  assert.has_error(function()
    unit.whileLoop('while {}')
  end)
  assert.has_error(function()
    unit.whileLoop('while 1 > 0')
  end)
  assert.has_error(function()
    unit.whileLoop('while 1 > 0 {')
  end)
  assert.has_error(function()
    unit.whileLoop('wihle 1 > 0 {}')
  end)
end)
