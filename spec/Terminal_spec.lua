local C = require('erde.constants')

describe('Terminal.parse', function()
  spec('ruleName', function()
    assert.are.equal('true', parse.Terminal('true'))
    assert.are.equal('Expr', parse.Terminal('(1 + 2)').ruleName)
    assert.are.equal('1', parse.Terminal('1'))
  end)

  spec('terminals', function()
    for _, terminal in pairs(C.TERMINALS) do
      assert.are.equal(terminal, parse.Terminal(terminal))
    end
  end)

  spec('terminal parens', function()
    assert.subtable({
      ruleName = 'String',
      parens = true,
    }, parse.Terminal(
      '("")'
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
