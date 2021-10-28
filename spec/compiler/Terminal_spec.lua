local constants = require('erde.constants')
local unit = require('erde.compiler.unit')

spec('terminals', function()
  for _, terminal in pairs(constants.TERMINALS) do
    assert.are.equal(terminal, unit.Terminal(terminal))
  end
end)
