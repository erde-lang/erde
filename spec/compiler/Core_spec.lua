local erde = require('erde')

describe('core', function()
  describe('comments', function()
    spec('single line comment', function()
      assert.are.equal('', erde.compile([[
        -- test
      ]]))
    end)
  end)
end)
