local unit = require('erde.compiler.unit')

spec('short comment', function()
  assert.is_nil(unit.Comment('-- hello world'))
  assert.is_nil(unit.Comment('-- hello world\nblah'))
end)

spec('long comment', function()
  assert.is_nil(unit.Comment('--- hello world---'))
  assert.is_nil(unit.Comment('--- hello world\nblah ---'))
end)
