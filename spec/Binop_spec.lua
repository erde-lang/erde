local C = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Binop.parse', function()
  spec('tokens', function()
    for opToken, op in pairs(C.BINOPS) do
      local testExpr = opToken == '?' and '1 ? 2 : 3' or '1 ' .. opToken .. ' 2'
      assert.subtable({ op = { token = opToken } }, parse.Expr(testExpr))
    end
  end)

  spec('left associative binop precedence', function()
    assert.subtable({
      op = { token = '+' },
      lhs = {
        op = { token = '*' },
        lhs = '1',
        rhs = '2',
      },
      rhs = '3',
    }, parse.Expr('1 * 2 + 3'))
    assert.subtable({
      op = { token = '+' },
      lhs = '1',
      rhs = {
        op = { token = '*' },
        lhs = '2',
        rhs = '3',
      },
    }, parse.Expr('1 + 2 * 3'))
    assert.subtable({
      op = { token = '+' },
      lhs = {
        op = { token = '+' },
        lhs = '1',
        rhs = {
          op = { token = '*' },
          lhs = '2',
          rhs = '3',
        },
      },
      rhs = '4',
    }, parse.Expr('1 + 2 * 3 + 4'))
  end)

  spec('right associative binop precedence', function()
    assert.subtable({
      op = { token = '^' },
      lhs = '1',
      rhs = {
        op = { token = '^' },
        lhs = '2',
        rhs = '3',
      },
    }, parse.Expr('1 ^ 2 ^ 3'))
    assert.subtable({
      op = { token = '+' },
      lhs = {
        op = { token = '^' },
        lhs = '1',
        rhs = '2',
      },
      rhs = '3',
    }, parse.Expr('1 ^ 2 + 3'))
  end)

  spec('binop parens', function()
    assert.subtable({
      op = { token = '*' },
      lhs = '1',
      rhs = {
        parens = true,
        op = { token = '+' },
        lhs = '2',
        rhs = '3',
      },
    }, parse.Expr('1 * (2 + 3)'))
  end)

  spec('ternary operator', function()
    assert.subtable({
      op = { token = '?' },
      lhs = '1',
      ternaryExpr = '2',
      rhs = '3',
    }, parse.Expr('1 ? 2 : 3'))
    assert.subtable({
      op = { token = '?' },
      lhs = '1',
      ternaryExpr = {
        op = { token = '-' },
        operand = '2',
      },
      rhs = {
        op = { token = '+' },
        lhs = '3',
        rhs = '4',
      },
    }, parse.Expr('1 ? -2 : 3 + 4'))
    assert.subtable({
      op = { token = '?' },
      lhs = '1',
      ternaryExpr = { ruleName = 'OptChain' },
      rhs = '2',
    }, parse.Expr('1 ? a:b() : 2'))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Binop.compile', function()
  spec('left associative binop precedence', function()
    assert.run(5, compile.Block('return 1 * 2 + 3'))
    assert.run(7, compile.Block('return 1 + 2 * 3'))
    assert.run(11, compile.Block('return 1 + 2 * 3 + 4'))
  end)

  spec('right associative binop precedence', function()
    assert.run(512, compile.Block('return 2 ^ 3 ^ 2'))
    assert.run(7, compile.Block('return 2 ^ 2 + 3'))
  end)

  spec('binop parens', function()
    assert.run(25, compile.Block('return 5 * (2 + 3)'))
  end)

  spec('ternary operator', function()
    assert.run(3, compile.Block('return false ? 2 : 3'))
    assert.run(2, compile.Block('return true ? 2 : 3'))
    assert.run(7, compile.Block('return false ? -2 : 3 + 4'))
  end)
end)
