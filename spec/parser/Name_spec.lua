local constants = require('erde.constants')
local unit = require('erde.parser.unit')

spec('name rule', function()
  assert.are.equal('Name', unit.Name('a').rule)
end)

spec('name', function()
  assert.are.equal('x', unit.Name('x').value)
  assert.are.equal('hello', unit.Name('hello').value)
  assert.are.equal('hello_world', unit.Name('hello_world').value)
  assert.are.equal('h1', unit.Name('h1').value)
  assert.has_error(function()
    unit.Name('1h')
  end)
end)

spec('prevent keyword names', function()
  for _, keyword in pairs(constants.KEYWORDS) do
    assert.has_error(function()
      unit.Name(keyword)
    end)
  end
end)
