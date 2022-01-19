-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Id.parse', function()
  spec('id', function()
    assert.has_error(function()
      parse.Id('a.b()')
    end)
    assert.has_no.errors(function()
      parse.Id('a.b')
    end)
  end)
end)
