local erde = require('erde')

describe('Functions', function()
  spec('function call', function()
    assert.are.equal('a()', erde.compile('a()'))
    assert.are.equal('a(x,y)', erde.compile('a(x, y)'))
    assert.are.equal('a.b.c()', erde.compile('a.b.c()'))
    assert.are.equal('a.b.c(x,y)', erde.compile('a.b.c(x, y)'))
    assert.are.equal('a.b:c()', erde.compile('a.b:c()'))
    assert.are.equal('a.b:c(x,y)', erde.compile('a.b:c(x, y)'))
  end)
end)