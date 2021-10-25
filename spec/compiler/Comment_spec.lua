local unit = require('erde.compiler.unit')

spec('compile short comment', function()
  assert.is_nil(unit.Comment('-- hello world'))
  assert.is_nil(unit.Comment('-- hello world\nblah'))
end)

spec('compile long comment', function()
  assert.is_nil(unit.Comment('--- hello world---'))
  assert.is_nil(unit.Comment('--- hello world\nblah ---'))
end)
