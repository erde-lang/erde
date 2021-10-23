local unit = require('erde.parser.unit')

spec('valid binops', function()
  assert.are.equal('pipe', unit.Expr('1 >> 2').op)
  assert.are.equal('ternary', unit.Expr('1 ? 2 : 3').op)
  assert.are.equal('nc', unit.Expr('1 ?? 2').op)
  assert.are.equal('or', unit.Expr('1 | 2').op)
  assert.are.equal('and', unit.Expr('1 & 2').op)
  assert.are.equal('eq', unit.Expr('1 == 2').op)
  assert.are.equal('neq', unit.Expr('1 ~= 2').op)
  assert.are.equal('lte', unit.Expr('1 <= 2').op)
  assert.are.equal('gte', unit.Expr('1 >= 2').op)
  assert.are.equal('lt', unit.Expr('1 < 2').op)
  assert.are.equal('gt', unit.Expr('1 > 2').op)
  assert.are.equal('bor', unit.Expr('1 .| 2').op)
  assert.are.equal('bxor', unit.Expr('1 .~ 2').op)
  assert.are.equal('band', unit.Expr('1 .& 2').op)
  assert.are.equal('lshift', unit.Expr('1 .<< 2').op)
  assert.are.equal('rshift', unit.Expr('1 .>> 2').op)
  assert.are.equal('concat', unit.Expr('1 .. 2').op)
  assert.are.equal('add', unit.Expr('1 + 2').op)
  assert.are.equal('sub', unit.Expr('1 - 2').op)
  assert.are.equal('mult', unit.Expr('1 * 2').op)
  assert.are.equal('div', unit.Expr('1 / 2').op)
  assert.are.equal('intdiv', unit.Expr('1 // 2').op)
  assert.are.equal('mod', unit.Expr('1 % 2').op)
  assert.are.equal('exp', unit.Expr('1 ^ 2').op)
end)

spec('left associative op precedence', function()
  assert.has_subtable({
    op = 'add',
    {
      op = 'mult',
      { value = '1' },
      { value = '2' },
    },
    { value = '3' },
  }, unit.Expr(
    '1 * 2 + 3'
  ))
  assert.has_subtable({
    op = 'add',
    { value = '1' },
    {
      op = 'mult',
      { value = '2' },
      { value = '3' },
    },
  }, unit.Expr(
    '1 + 2 * 3'
  ))
  assert.has_subtable({
    op = 'add',
    {
      op = 'add',
      { value = '1' },
      {
        op = 'mult',
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
    op = 'exp',
    { value = '1' },
    {
      op = 'exp',
      { value = '2' },
      { value = '3' },
    },
  }, unit.Expr(
    '1 ^ 2 ^ 3'
  ))
  assert.has_subtable({
    op = 'add',
    {
      op = 'exp',
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
    op = 'mult',
    { value = '1' },
    {
      parens = true,
      op = 'add',
      { value = '2' },
      { value = '3' },
    },
  }, unit.Expr(
    '1 * (2 + 3)'
  ))
end)

spec('unops', function()
  assert.has_subtable({
    op = 'mult',
    { value = '1' },
    {
      op = 'neg',
      { value = '3' },
    },
  }, unit.Expr(
    '1 * -3'
  ))
  assert.has_subtable({
    op = 'neg',
    {
      op = 'exp',
      { value = '2' },
      { value = '3' },
    },
  }, unit.Expr(
    '-2 ^ 3'
  ))
  assert.has_subtable({
    op = 'mult',
    {
      op = 'neg',
      { value = '2' },
    },
    { value = '3' },
  }, unit.Expr(
    '-2 * 3'
  ))
end)

spec('ternary', function()
  assert.has_subtable({
    op = 'ternary',
    { value = '1' },
    { value = '2' },
    { value = '3' },
  }, unit.Expr(
    '1 ? 2 : 3'
  ))
  assert.has_subtable({
    op = 'ternary',
    { value = '1' },
    {
      op = 'neg',
      { value = '2' },
    },
    {
      op = 'add',
      { value = '3' },
      { value = '4' },
    },
  }, unit.Expr(
    '1 ? -2 : 3 + 4'
  ))
end)
