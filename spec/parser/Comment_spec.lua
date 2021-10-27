local unit = require('erde.parser.unit')

spec('comment rule', function()
  assert.are.equal('Comment', unit.Comment('-- hello world').rule)
end)

spec('short comments', function()
  assert.are.equal(' hello world', unit.Comment('-- hello world').value)
  assert.are.equal(' hello world', unit.Comment('-- hello world\nblah').value)
end)

spec('long comments', function()
  assert.are.equal(' hello world', unit.Comment('--- hello world---').value)
  assert.are.equal(
    ' hello world\nblah ',
    unit.Comment('--- hello world\nblah ---').value
  )
  assert.has_error(function()
    unit.Comment('--- hello')
  end)
end)
