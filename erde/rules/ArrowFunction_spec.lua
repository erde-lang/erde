local ParserContext = require('erde.ParserContext')

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('ArrowFunction.parse', function()
  setup(function()
    ctx = ParserContext()
    unitParse = function(input)
      ctx:load(input)
      return ctx.ArrowFunction.parse(ctx)
    end
  end)

  spec('rule', function()
    assert.are.equal('ArrowFunction', unitParse('() -> {}').rule)
  end)

  spec('skinny variant', function()
    assert.has_subtable({
      variant = 'skinny',
      body = { { rule = 'Return' } },
    }, unitParse(
      '() -> { return 1 }'
    ))
  end)

  spec('fat variant', function()
    assert.has_subtable({
      variant = 'fat',
      body = { { rule = 'Return' } },
    }, unitParse(
      '() => { return 1 }'
    ))
  end)

  spec('implicit params', function()
    assert.has_subtable({
      hasImplicitParams = true,
      paramName = 'a',
    }, unitParse(
      'a -> {}'
    ))
    assert.has_error(function()
      unitParse('a.b -> {}')
    end)
  end)

  spec('implicit returns', function()
    assert.has_subtable({
      hasImplicitReturns = true,
      returns = { { value = '1' } },
    }, unitParse(
      '() -> 1'
    ))
    assert.has_subtable({
      hasImplicitReturns = true,
      returns = {
        { value = '1' },
        { value = '2' },
      },
    }, unitParse(
      '() => 1, 2'
    ))
    assert.has_error(function()
      unitParse('() ->')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('ArrowFunction.compile', function()
  -- TODO
end)
