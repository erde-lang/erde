local stringParser = require('erde.parser.string')

spec('valid short string', function()
  assert.are.equal('"hello"', stringParser.unit('"hello"'))
  assert.are.equal("'hello'", stringParser.unit("'hello'"))
  assert.are.equal("'hello\\nworld'", stringParser.unit("'hello\\nworld'"))
  assert.are.equal("'\\\\'", stringParser.unit("'\\\\'"))
end)

spec('invalid short string', function()
  assert.has_error(function()
    stringParser.unit('hello"')
  end)
  assert.has_error(function()
    stringParser.unit('"hello')
  end)
  assert.has_error(function()
    stringParser.unit('"hello\nworld"')
  end)
  assert.has_error(function()
    stringParser.unit("hello'")
  end)
  assert.has_error(function()
    stringParser.unit("'hello")
  end)
  assert.has_error(function()
    stringParser.unit("'hello\nworld'")
  end)
end)
