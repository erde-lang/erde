local unit = require('erde.parser.unit')

spec('valid binops', function()
  assert.are.equal('pipe', unit.Expr('1 >> 2').op.tag)
  assert.are.equal('ternary', unit.Expr('1 ? 2 : 3').op.tag)
  assert.are.equal('nc', unit.Expr('1 ?? 2').op.tag)
  assert.are.equal('or', unit.Expr('1 | 2').op.tag)
  assert.are.equal('and', unit.Expr('1 & 2').op.tag)
  assert.are.equal('eq', unit.Expr('1 == 2').op.tag)
  assert.are.equal('neq', unit.Expr('1 ~= 2').op.tag)
  assert.are.equal('lte', unit.Expr('1 <= 2').op.tag)
  assert.are.equal('gte', unit.Expr('1 >= 2').op.tag)
  assert.are.equal('lt', unit.Expr('1 < 2').op.tag)
  assert.are.equal('gt', unit.Expr('1 > 2').op.tag)
  assert.are.equal('bor', unit.Expr('1 .| 2').op.tag)
  assert.are.equal('bxor', unit.Expr('1 .~ 2').op.tag)
  assert.are.equal('band', unit.Expr('1 .& 2').op.tag)
  assert.are.equal('lshift', unit.Expr('1 .<< 2').op.tag)
  assert.are.equal('rshift', unit.Expr('1 .>> 2').op.tag)
  assert.are.equal('concat', unit.Expr('1 .. 2').op.tag)
  assert.are.equal('add', unit.Expr('1 + 2').op.tag)
  assert.are.equal('sub', unit.Expr('1 - 2').op.tag)
  assert.are.equal('mult', unit.Expr('1 * 2').op.tag)
  assert.are.equal('div', unit.Expr('1 / 2').op.tag)
  assert.are.equal('intdiv', unit.Expr('1 // 2').op.tag)
  assert.are.equal('mod', unit.Expr('1 % 2').op.tag)
  assert.are.equal('exp', unit.Expr('1 ^ 2').op.tag)
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

spec('ternary', function()
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
