local unit = require('erde.parser.unit')

spec('valid binops', function()
  assert.are.equal('TAG_PIPE', unit.expr('1 >> 2').tag)
  assert.are.equal('TAG_TERNARY', unit.expr('1 ? 2 : 3').tag)
  assert.are.equal('TAG_NC', unit.expr('1 ?? 2').tag)
  assert.are.equal('TAG_OR', unit.expr('1 | 2').tag)
  assert.are.equal('TAG_AND', unit.expr('1 & 2').tag)
  assert.are.equal('TAG_EQ', unit.expr('1 == 2').tag)
  assert.are.equal('TAG_NEQ', unit.expr('1 ~= 2').tag)
  assert.are.equal('TAG_LTE', unit.expr('1 <= 2').tag)
  assert.are.equal('TAG_GTE', unit.expr('1 >= 2').tag)
  assert.are.equal('TAG_LT', unit.expr('1 < 2').tag)
  assert.are.equal('TAG_GT', unit.expr('1 > 2').tag)
  assert.are.equal('TAG_BOR', unit.expr('1 .| 2').tag)
  assert.are.equal('TAG_BXOR', unit.expr('1 .~ 2').tag)
  assert.are.equal('TAG_BAND', unit.expr('1 .& 2').tag)
  assert.are.equal('TAG_LSHIFT', unit.expr('1 .<< 2').tag)
  assert.are.equal('TAG_RSHIFT', unit.expr('1 .>> 2').tag)
  assert.are.equal('TAG_CONCAT', unit.expr('1 .. 2').tag)
  assert.are.equal('TAG_ADD', unit.expr('1 + 2').tag)
  assert.are.equal('TAG_SUB', unit.expr('1 - 2').tag)
  assert.are.equal('TAG_MULT', unit.expr('1 * 2').tag)
  assert.are.equal('TAG_DIV', unit.expr('1 / 2').tag)
  assert.are.equal('TAG_INTDIV', unit.expr('1 // 2').tag)
  assert.are.equal('TAG_MOD', unit.expr('1 % 2').tag)
  assert.are.equal('TAG_EXP', unit.expr('1 ^ 2').tag)
end)

spec('left associative op precedence', function()
  assert.has_subtable({
    tag = 'TAG_ADD',
    {
      tag = 'TAG_MULT',
      { value = '1' },
      { value = '2' },
    },
    { value = '3' },
  }, unit.expr(
    '1 * 2 + 3'
  ))
  assert.has_subtable({
    tag = 'TAG_ADD',
    { value = '1' },
    {
      tag = 'TAG_MULT',
      { value = '2' },
      { value = '3' },
    },
  }, unit.expr(
    '1 + 2 * 3'
  ))
  assert.has_subtable({
    tag = 'TAG_ADD',
    {
      tag = 'TAG_ADD',
      { value = '1' },
      {
        tag = 'TAG_MULT',
        { value = '2' },
        { value = '3' },
      },
    },
    { value = '4' },
  }, unit.expr(
    '1 + 2 * 3 + 4'
  ))
end)

spec('right associative binop precedence', function()
  assert.has_subtable({
    tag = 'TAG_EXP',
    { value = '1' },
    {
      tag = 'TAG_EXP',
      { value = '2' },
      { value = '3' },
    },
  }, unit.expr(
    '1 ^ 2 ^ 3'
  ))
  assert.has_subtable({
    tag = 'TAG_ADD',
    {
      tag = 'TAG_EXP',
      { value = '1' },
      { value = '2' },
    },
    { value = '3' },
  }, unit.expr(
    '1 ^ 2 + 3'
  ))
end)

spec('binop parens', function()
  assert.has_subtable({
    tag = 'TAG_MULT',
    { value = '1' },
    {
      parens = true,
      tag = 'TAG_ADD',
      { value = '2' },
      { value = '3' },
    },
  }, unit.expr(
    '1 * (2 + 3)'
  ))
end)

spec('unops', function()
  assert.has_subtable({
    tag = 'TAG_MULT',
    { value = '1' },
    {
      tag = 'TAG_NEG',
      { value = '3' },
    },
  }, unit.expr(
    '1 * -3'
  ))
  assert.has_subtable({
    tag = 'TAG_NEG',
    {
      tag = 'TAG_EXP',
      { value = '2' },
      { value = '3' },
    },
  }, unit.expr(
    '-2 ^ 3'
  ))
  assert.has_subtable({
    tag = 'TAG_MULT',
    {
      tag = 'TAG_NEG',
      { value = '2' },
    },
    { value = '3' },
  }, unit.expr(
    '-2 * 3'
  ))
end)

spec('ternary', function()
  assert.has_subtable({
    tag = 'TAG_TERNARY',
    { value = '1' },
    { value = '2' },
    { value = '3' },
  }, unit.expr(
    '1 ? 2 : 3'
  ))
  assert.has_subtable({
    tag = 'TAG_TERNARY',
    { value = '1' },
    {
      tag = 'TAG_NEG',
      { value = '2' },
    },
    {
      tag = 'TAG_ADD',
      { value = '3' },
      { value = '4' },
    },
  }, unit.expr(
    '1 ? -2 : 3 + 4'
  ))
end)
