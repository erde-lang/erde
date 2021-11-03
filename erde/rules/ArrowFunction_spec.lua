local ParserContext = require('erde.ParserContext')

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('ArrowFunction.parse', function()
  spec('rule', function()
    assert.are.equal('ArrowFunction', parse.ArrowFunction('() -> {}').rule)
  end)

  spec('skinny arrow function', function()
    assert.has_subtable({
      variant = 'skinny',
      body = { { rule = 'Return' } },
    }, parse.ArrowFunction(
      '() -> { return 1 }'
    ))
  end)

  spec('fat arrow function', function()
    assert.has_subtable({
      variant = 'fat',
      body = { { rule = 'Return' } },
    }, parse.ArrowFunction(
      '() => { return 1 }'
    ))
  end)

  spec('arrow function implicit params', function()
    assert.has_subtable({
      hasImplicitParams = true,
      paramName = 'a',
    }, parse.ArrowFunction(
      'a -> {}'
    ))
    assert.has_error(function()
      parse.ArrowFunction('a.b -> {}')
    end)
  end)

  spec('arrow function implicit returns', function()
    assert.has_subtable({
      hasImplicitReturns = true,
      returns = { { value = '1' } },
    }, parse.ArrowFunction(
      '() -> 1'
    ))
    assert.has_subtable({
      hasImplicitReturns = true,
      returns = {
        { value = '1' },
        { value = '2' },
      },
    }, parse.ArrowFunction(
      '() => 1, 2'
    ))
    assert.has_error(function()
      parse.ArrowFunction('() ->')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('ArrowFunction.compile', function()
  -- TODO
end)
