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

  spec('unop tags', function()
    for token, op in pairs(C.UNOPS) do
      assert.has_subtable({
        variant = 'unop',
        op = { tag = op.tag },
      }, parse.Expr(
        token .. '1'
      ))
    end
  end)

  spec('binop tags', function()
    for token, op in pairs(C.BINOPS) do
      local testExpr = op.tag == 'ternary' and '1 ? 2 : 3'
        or '1' .. token .. '2'
      assert.has_subtable({
        variant = 'binop',
        op = { tag = op.tag },
      }, parse.Expr(
        testExpr
      ))
    end
  end)

  spec('left associative binop precedence', function()
    assert.has_subtable({
      op = { tag = 'add' },
      {
        op = { tag = 'mult' },
        { value = '1' },
        { value = '2' },
      },
      { value = '3' },
    }, parse.Expr(
      '1 * 2 + 3'
    ))
    assert.has_subtable({
      op = { tag = 'add' },
      { value = '1' },
      {
        op = { tag = 'mult' },
        { value = '2' },
        { value = '3' },
      },
    }, parse.Expr(
      '1 + 2 * 3'
    ))
    assert.has_subtable({
      op = { tag = 'add' },
      {
        op = { tag = 'add' },
        { value = '1' },
        {
          op = { tag = 'mult' },
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
      op = { tag = 'exp' },
      { value = '1' },
      {
        op = { tag = 'exp' },
        { value = '2' },
        { value = '3' },
      },
    }, parse.Expr(
      '1 ^ 2 ^ 3'
    ))
    assert.has_subtable({
      op = { tag = 'add' },
      {
        op = { tag = 'exp' },
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
      op = { tag = 'mult' },
      { value = '1' },
      {
        parens = true,
        op = { tag = 'add' },
        { value = '2' },
        { value = '3' },
      },
    }, parse.Expr(
      '1 * (2 + 3)'
    ))
  end)

  spec('unops', function()
    assert.has_subtable({
      op = { tag = 'mult' },
      { value = '1' },
      {
        op = { tag = 'neg' },
        operand = { value = '3' },
      },
    }, parse.Expr(
      '1 * -3'
    ))
    assert.has_subtable({
      op = { tag = 'neg' },
      operand = {
        op = { tag = 'exp' },
        { value = '2' },
        { value = '3' },
      },
    }, parse.Expr(
      '-2 ^ 3'
    ))
    assert.has_subtable({
      op = { tag = 'mult' },
      {
        op = { tag = 'neg' },
        operand = { value = '2' },
      },
      { value = '3' },
    }, parse.Expr(
      '-2 * 3'
    ))
  end)

  spec('ternary operator', function()
    assert.has_subtable({
      op = { tag = 'ternary' },
      { value = '1' },
      { value = '2' },
      { value = '3' },
    }, parse.Expr(
      '1 ? 2 : 3'
    ))
    assert.has_subtable({
      op = { tag = 'ternary' },
      { value = '1' },
      {
        op = { tag = 'neg' },
        operand = { value = '2' },
      },
      {
        op = { tag = 'add' },
        { value = '3' },
        { value = '4' },
      },
    }, parse.Expr(
      '1 ? -2 : 3 + 4'
    ))
    assert.has_subtable({
      op = { tag = 'ternary' },
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
