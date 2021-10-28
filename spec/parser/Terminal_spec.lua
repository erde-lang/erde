local constants = require('erde.constants')
local unit = require('erde.parser.unit')

spec('terminal rule', function()
  assert.are.equal('Terminal', unit.Terminal('true').rule)
  assert.are.equal('Expr', unit.Terminal('(1 + 2)').rule)
  assert.are.equal('Number', unit.Terminal('1').rule)
end)

spec('terminals', function()
  for _, terminal in pairs(constants.TERMINALS) do
    assert.are.equal(terminal, unit.Terminal(terminal).value)
  end
end)

spec('terminal parens', function()
  assert.has_subtable({
    rule = 'Number',
    value = '1',
    parens = true,
  }, unit.Terminal(
    '(1)'
  ))
  assert.has_subtable({
    rule = 'ArrowFunction',
    parens = true,
  }, unit.Terminal(
    '(() -> {})'
  ))
  assert.has_error(function()
    unit.Terminal('()')
  end)
end)
