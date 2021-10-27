local unit = require('erde.parser.unit')

local KEYWORDS = {
  'local',
  'global',
  'if',
  'elseif',
  'else',
  'for',
  'in',
  'while',
  'repeat',
  'until',
  'do',
  'function',
  'false',
  'true',
  'nil',
  'return',
  'self',
}

spec('valid names', function()
  assert.are.equal('x', unit.Name('x').value)
  assert.are.equal('hello', unit.Name('hello').value)
  assert.are.equal('hello_world', unit.Name('hello_world').value)
  assert.are.equal('h1', unit.Name('h1').value)
end)

spec('invalid names', function()
  assert.has_error(function()
    unit.Name('1h')
  end)

  for _, keyword in pairs(KEYWORDS) do
    assert.has_error(function()
      unit.Name(keyword)
    end)
  end
end)
