local erde = require('erde')

describe('Core', function()
  spec('output: Comment (single line)', function()
    assert.are.equal('', erde.compile('-- test'))
  end)
  spec('output: Comment (multi line)', function()
    assert.are.equal('', erde.compile([[
    ---
    -- This is a
    -- multiline comment
    ---
    ]]))
  end)
  spec('output: Declaration', function()
    assert.are.equal('local x', erde.compile('local x'))
    assert.are.equal('local x1', erde.compile('local x1'))
    assert.has_error(function() erde.compile('local 1x') end)
  end)
end)
