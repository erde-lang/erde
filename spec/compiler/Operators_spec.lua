local erde = require('erde')

spec('unary op', function()
  assert.are.equal('local x = -2', erde.compile('local x = -2'))
end)
