local unit = require('erde.compiler.unit')

spec('number compile', function()
  assert.are.equal('0xffea34', unit.Number('0xffea34'))
end)
