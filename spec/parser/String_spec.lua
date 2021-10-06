local stringParser = require('erde.parser.string')

spec('valid single quote string', function()
  assert.are.equal('"hello"', stringParser.unit('"hello"'))
end)
