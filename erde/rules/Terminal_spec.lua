local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Terminal.parse', function()
  spec('rule', function()
    assert.are.equal('Terminal', parse.Terminal('true').rule)
    assert.are.equal('Expr', parse.Terminal('(1 + 2)').rule)
    assert.are.equal('Number', parse.Terminal('1').rule)
  end)

  spec('terminals', function()
    for _, terminal in pairs(constants.TERMINALS) do
      assert.are.equal(terminal, parse.Terminal(terminal).value)
    end
  end)

  spec('terminal parens', function()
    assert.has_subtable({
      rule = 'Number',
      value = '1',
      parens = true,
    }, parse.Terminal(
      '(1)'
    ))
    assert.has_subtable({
      rule = 'ArrowFunction',
      parens = true,
    }, parse.Terminal(
      '(() -> {})'
    ))
    assert.has_error(function()
      parse.Terminal('()')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Terminal.compile', function()
  spec('terminals', function()
    for _, terminal in pairs(constants.TERMINALS) do
      assert.are.equal(terminal, compile.Terminal(terminal))
    end
  end)
end)
