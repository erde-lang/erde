local C = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Terminal.parse', function()
  spec('ruleName', function()
    assert.are.equal('Terminal', parse.Terminal('true').ruleName)
    assert.are.equal('Expr', parse.Terminal('(1 + 2)').ruleName)
    assert.are.equal('Number', parse.Terminal('1').ruleName)
  end)

  spec('terminals', function()
    for _, terminal in pairs(C.TERMINALS) do
      assert.are.equal(terminal, parse.Terminal(terminal).value)
    end
  end)

  spec('terminal parens', function()
    assert.subtable({
      ruleName = 'Number',
      value = '1',
      parens = true,
    }, parse.Terminal(
      '(1)'
    ))
    assert.subtable({
      ruleName = 'ArrowFunction',
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
    for _, terminal in pairs(C.TERMINALS) do
      assert.are.equal(terminal, compile.Terminal(terminal))
    end
  end)
end)
