local unit = require('erde.parser.unit')

spec('valid short comment', function()
  assert.are.equal(' hello world', unit.comment('-- hello world'))
  assert.are.equal(' hello world', unit.comment('-- hello world\nblah'))
end)

spec('invalid short comment', function()
  assert.has_error(function()
    unit.comment('')
  end)
end)

spec('valid long comment', function()
  assert.are.equal(' hello world', unit.comment('--- hello world---'))
  assert.are.equal(
    ' hello world\nblah ',
    unit.comment('--- hello world\nblah ---')
  )
end)

spec('invalid long comment', function()
  assert.has_error(function()
    unit.comment('--- hello')
  end)
end)
