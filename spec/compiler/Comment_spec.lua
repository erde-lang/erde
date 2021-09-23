local erde = require('erde')

describe('Core', function()
  spec('output: single line comment', function()
    assert.are.equal('', erde.compile('-- test'))
  end)
  spec('output: multi line comment', function()
    assert.are.equal('', erde.compile([[
    ---
    -- This is a
    -- multiline comment
    ---
    ]]))
  end)
  spec('output: name', function()
    assert.are.equal('local x', erde.compile('local x'))
    assert.are.equal('local x1', erde.compile('local x1'))
    assert.has_error(function() erde.compile('local 1x') end)
  end)
end)
