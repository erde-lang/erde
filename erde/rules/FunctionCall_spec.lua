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

  spec('stdlib', function()
    assert.has_subtable({
      base = {
        value = '__ERDESTD_SPLIT__',
      },
      {
        optional = false,
        variant = 'functionCall',
      },
    }, parse.FunctionCall(
      '!split("hello world")'
    ))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('FunctionCall.compile', function()
  spec('stdlib', function()
    assert.run(
      { 'hello', 'world' },
      compile.Block('return !split("hello world")', { isModuleBlock = true })
    )
  end)
end)
