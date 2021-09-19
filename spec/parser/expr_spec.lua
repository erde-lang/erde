local unit = require('erde.parser.unit')

spec('valid expr', function()
  assert.are.same('"hello"', unit.expr('1 + 2'))
end)
