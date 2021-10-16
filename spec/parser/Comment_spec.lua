local unit = require('erde.parser.unit')

spec('valid short comment', function()
  assert.are.equal(' hello world', unit.Comment('-- hello world').value)
  assert.are.equal(' hello world', unit.Comment('-- hello world\nblah').value)
end)

spec('invalid short comment', function()
  assert.has_error(function()
    unit.Comment('')
  end)
end)

spec('valid long comment', function()
  assert.are.equal(' hello world', unit.Comment('--- hello world---').value)
  assert.are.equal(
    ' hello world\nblah ',
    unit.Comment('--- hello world\nblah ---').value
  )
end)

spec('invalid long comment', function()
  assert.has_error(function()
    unit.Comment('--- hello')
  end)
end)
