local unit = require('erde.compiler.unit')

spec('short string compile', function()
  assert.are.equal('"hello world"', unit.String('"hello world"'))
end)

spec('long string compile', function()
  assert.are.equal('"hello world"', unit.String('`1 + 1 is {1+1}`'))
end)
