local C = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Expr.parse', function()
  spec('ruleName', function()
    assert.are.equal('Expr', parse.Expr('1 + 2').ruleName)
    assert.are.equal('Number', parse.Expr('1').ruleName)
    assert.are.equal('String', parse.Expr('"hello"').ruleName)
  end)

  spec('unop tokens', function()
    for opToken, op in pairs(C.UNOPS) do
      assert.has_subtable({
        variant = 'unop',
        op = { token = op.token },
      }, parse.Expr(
        opToken .. '1'
      ))
    end
  end)

  spec('binop tokens', function()
    for opToken, op in pairs(C.BINOPS) do
      local testExpr = op.token == '?' and '1 ? 2 : 3' or '1' .. opToken .. '2'
      assert.has_subtable({
        variant = 'binop',
        op = { token = op.token },
      }, parse.Expr(
        testExpr
      ))
    end
  end)

  spec('left associative binop precedence', function()
    assert.has_subtable({
      op = { token = '+' },
      {
        op = { token = '*' },
        { value = '1' },
        { value = '2' },
      },
      { value = '3' },
    }, parse.Expr(
      '1 * 2 + 3'
    ))
    assert.has_subtable({
      op = { token = '+' },
      { value = '1' },
      {
        op = { token = '*' },
        { value = '2' },
        { value = '3' },
      },
    }, parse.Expr(
      '1 + 2 * 3'
    ))
    assert.has_subtable({
      op = { token = '+' },
      {
        op = { token = '+' },
        { value = '1' },
        {
          op = { token = '*' },
          { value = '2' },
          { value = '3' },
        },
      },
      { value = '4' },
    }, parse.Expr(
      '1 + 2 * 3 + 4'
    ))
  end)

  spec('right associative binop precedence', function()
    assert.has_subtable({
      op = { token = '^' },
      { value = '1' },
      {
        op = { token = '^' },
        { value = '2' },
        { value = '3' },
      },
    }, parse.Expr(
      '1 ^ 2 ^ 3'
    ))
    assert.has_subtable({
      op = { token = '+' },
      {
        op = { token = '^' },
        { value = '1' },
        { value = '2' },
      },
      { value = '3' },
    }, parse.Expr(
      '1 ^ 2 + 3'
    ))
  end)

  spec('binop parens', function()
    assert.has_subtable({
      op = { token = '*' },
      { value = '1' },
      {
        parens = true,
        op = { token = '+' },
        { value = '2' },
        { value = '3' },
      },
    }, parse.Expr(
      '1 * (2 + 3)'
    ))
  end)

  spec('unops', function()
    assert.has_subtable({
      op = { token = '*' },
      { value = '1' },
      {
        op = { token = '-' },
        operand = { value = '3' },
      },
    }, parse.Expr(
      '1 * -3'
    ))
    assert.has_subtable({
      op = { token = '-' },
      operand = {
        op = { token = '^' },
        { value = '2' },
        { value = '3' },
      },
    }, parse.Expr(
      '-2 ^ 3'
    ))
    assert.has_subtable({
      op = { token = '*' },
      {
        op = { token = '-' },
        operand = { value = '2' },
      },
      { value = '3' },
    }, parse.Expr(
      '-2 * 3'
    ))
  end)

  spec('ternary operator', function()
    assert.has_subtable({
      op = { token = '?' },
      { value = '1' },
      { value = '2' },
      { value = '3' },
    }, parse.Expr(
      '1 ? 2 : 3'
    ))
    assert.has_subtable({
      op = { token = '?' },
      { value = '1' },
      {
        op = { token = '-' },
        operand = { value = '2' },
      },
      {
        op = { token = '+' },
        { value = '3' },
        { value = '4' },
      },
    }, parse.Expr(
      '1 ? -2 : 3 + 4'
    ))
    assert.has_subtable({
      op = { token = '?' },
      { value = '1' },
      { ruleName = 'OptChain' },
      { ruleName = 'Number' },
    }, parse.Expr(
      '1 ? a:b() : 2'
    ))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Expr.compile', function()
  spec('left associative binop precedence', function()
    assert.eval(5, compile.Expr('1 * 2 + 3'))
    assert.eval(7, compile.Expr('1 + 2 * 3'))
    assert.eval(11, compile.Expr('1 + 2 * 3 + 4'))
  end)

  spec('right associative binop precedence', function()
    assert.eval(512, compile.Expr('2 ^ 3 ^ 2'))
    assert.eval(7, compile.Expr('2 ^ 2 + 3'))
  end)

  spec('binop parens', function()
    assert.eval(25, compile.Expr('5 * (2 + 3)'))
  end)

  spec('unops', function()
    assert.eval(-6, compile.Expr('2 * -3'))
    assert.eval(-6, compile.Expr('-2 * 3'))
    assert.eval(-8, compile.Expr('-2 ^ 3'))
  end)

  spec('ternary operator', function()
    assert.eval(3, compile.Expr('false ? 2 : 3'))
    assert.eval(2, compile.Expr('true ? 2 : 3'))
    assert.eval(7, compile.Expr('false ? -2 : 3 + 4'))
  end)
end)
