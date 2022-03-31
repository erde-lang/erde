local C = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Unop.parse', function()
  spec('tokens', function()
    for opToken, op in pairs(C.UNOPS) do
      assert.subtable({ op = { token = opToken } }, parse.Unop(opToken .. '1'))
    end
  end)

  spec('unops', function()
    assert.subtable({
      op = { token = '*' },
      lhs = '1',
      rhs = {
        op = { token = '-' },
        operand = '3',
      },
    }, parse.Expr('1 * -3'))
    assert.subtable({
      op = { token = '-' },
      operand = {
        op = { token = '^' },
        lhs = '2',
        rhs = '3',
      },
    }, parse.Expr('-2 ^ 3'))
    assert.subtable({
      op = { token = '*' },
      lhs = {
        op = { token = '-' },
        operand = '2',
      },
      rhs = '3',
    }, parse.Expr('-2 * 3'))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Unop.compile', function()
  spec('unops', function()
    assert.run(-6, compile.Block('return 2 * -3'))
    assert.run(-6, compile.Block('return -2 * 3'))
    assert.run(-8, compile.Block('return -2 ^ 3'))
  end)
end)
