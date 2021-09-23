local erde = require('erde')

describe('Block', function()
  spec('declarations', function()
    assert.are.equal('local x', erde.compile('local x'))
    assert.are.equal('local x1', erde.compile('local x1'))
    assert.are.equal('x = 1', erde.compile('global x = 1'))
    assert.are.equal('', erde.compile('global x'))
    assert.has_error(function() erde.compile('local 1x') end)
  end)
  spec('assignment', function()
    assert.are.equal('a = 1', erde.compile('a = 1'))
    assert.are.equal('a.b.c = 1', erde.compile('a.b.c = 1'))
  end)
end)
