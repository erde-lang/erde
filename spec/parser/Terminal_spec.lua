local unit = require('erde.parser.unit')

spec('terminal rule', function()
  assert.are.equal('Terminal', unit.Terminal('true').rule)
  assert.are.equal('Expr', unit.Terminal('(1 + 2)').rule)
  assert.are.equal('Number', unit.Terminal('1').rule)
end)

spec('terminals', function()
  assert.are.equal('true', unit.Terminal('true').value)
  assert.are.equal('false', unit.Terminal('false').value)
  assert.are.equal('nil', unit.Terminal('nil').value)
  assert.are.equal('...', unit.Terminal('...').value)
end)
