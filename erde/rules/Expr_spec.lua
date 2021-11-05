local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Expr.parse', function()
  spec('rule', function()
    assert.are.equal('Expr', unit.Expr('1 + 2').rule)
    assert.are.equal('Number', unit.Expr('1').rule)
    assert.are.equal('String', unit.Expr('"hello"').rule)
  end)

  spec('unop tags', function()
    for _, op in pairs(constants.UNOPS) do
      assert.has_subtable({
        variant = 'unop',
        op = { tag = op.tag },
      }, unit.Expr(
        op.token .. '1'
      ))
    end
  end)

  spec('binop tags', function()
    for _, op in pairs(constants.BINOPS) do
      local testExpr = op.tag == 'ternary' and '1 ? 2 : 3'
        or '1' .. op.token .. '2'
      assert.has_subtable({
        variant = 'binop',
        op = { tag = op.tag },
      }, unit.Expr(
        testExpr
      ))
    end
  end)

  spec('left associative op precedence', function()
    assert.has_subtable({
      op = { tag = 'add' },
      {
        op = { tag = 'mult' },
        { value = '1' },
        { value = '2' },
      },
      { value = '3' },
    }, unit.Expr(
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
    }, unit.Expr(
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
    }, unit.Expr(
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
    }, unit.Expr(
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
    }, unit.Expr(
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
    }, unit.Expr(
      '1 * (2 + 3)'
    ))
  end)

  spec('unops', function()
    assert.has_subtable({
      op = { tag = 'mult' },
      { value = '1' },
      {
        op = { tag = 'neg' },
        { value = '3' },
      },
    }, unit.Expr(
      '1 * -3'
    ))
    assert.has_subtable({
      op = { tag = 'neg' },
      {
        op = { tag = 'exp' },
        { value = '2' },
        { value = '3' },
      },
    }, unit.Expr(
      '-2 ^ 3'
    ))
    assert.has_subtable({
      op = { tag = 'mult' },
      {
        op = { tag = 'neg' },
        { value = '2' },
      },
      { value = '3' },
    }, unit.Expr(
      '-2 * 3'
    ))
  end)

  spec('ternary operator', function()
    assert.has_subtable({
      op = { tag = 'ternary' },
      { value = '1' },
      { value = '2' },
      { value = '3' },
    }, unit.Expr(
      '1 ? 2 : 3'
    ))
    assert.has_subtable({
      op = { tag = 'ternary' },
      { value = '1' },
      {
        op = { tag = 'neg' },
        { value = '2' },
      },
      {
        op = { tag = 'add' },
        { value = '3' },
        { value = '4' },
      },
    }, unit.Expr(
      '1 ? -2 : 3 + 4'
    ))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Expr.compile', function()
  -- TODO
end)
