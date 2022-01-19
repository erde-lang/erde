-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('FunctionCall.parse', function()
  spec('function call', function()
    assert.has_error(function()
      parse.FunctionCall('a')
    end)
    assert.has_error(function()
      parse.FunctionCall('a.b')
    end)
    assert.has_no.errors(function()
      parse.FunctionCall('hello()')
    end)
  end)
end)
