-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Std.parse', function()
  spec('parse', function()
    assert.has_subtable({
      base = {
        value = '__ERDESTD_SPLIT__',
      },
      {
        optional = false,
        variant = 'functionCall',
      },
    }, parse.Std(
      '!split("hello world")'
    ))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Std.compile', function()
  spec('std', function()
    assert.run(
      { 'hello', 'world' },
      compile.Block('return !split("hello world")', { isModuleBlock = true })
    )
  end)
end)
