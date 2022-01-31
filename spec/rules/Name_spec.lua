local C = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Name.parse', function()
  spec('name', function()
    assert.are.equal('x', parse.Name('x').value)
    assert.are.equal('hello', parse.Name('hello').value)
    assert.are.equal('_hello_world', parse.Name('_hello_world').value)
    assert.are.equal('h1', parse.Name('h1').value)
    assert.has_error(function()
      parse.Name('1h')
    end)
  end)

  spec('prevent keyword names', function()
    for _, keyword in pairs(C.KEYWORDS) do
      assert.has_error(function()
        parse.Name(keyword)
      end)
    end
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Name.compile', function()
  spec('sanity check', function()
    assert.has.no_error(function()
      compile.Name('a')
    end)
  end)
end)
