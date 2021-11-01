local unit = require('erde.parser.unit')

spec('assignment rule', function()
  assert.are.equal('Assignment', unit.Assignment('a = 1').rule)
end)

spec('assignment', function()
  assert.has_subtable({
    idList = { { value = 'a' } },
    exprList = { { value = '3' } },
  }, unit.Assignment(
    'a = 3'
  ))
  assert.has_subtable({
    idList = { { rule = 'OptChain' } },
    exprList = { { value = '3' } },
  }, unit.Assignment(
    'a.b = 3'
  ))
end)

spec('multiple assignment', function()
  assert.has_subtable({
    idList = {
      { value = 'a' },
      { value = 'b' },
    },
    exprList = {
      { value = '1' },
      { value = '2' },
    },
  }, unit.Assignment(
    'a, b = 1, 2'
  ))
  assert.has_subtable({
    idList = {
      { value = 'a' },
      { rule = 'OptChain' },
    },
    exprList = {
      { value = '1' },
      { value = '2' },
    },
  }, unit.Assignment(
    'a, b.c = 1, 2'
  ))
  assert.has_error(function()
    unit.Assignment('a, b += 1, 2')
  end)
  assert.has_error(function()
    unit.Var('a, = 1')
  end)
  assert.has_error(function()
    unit.Var('a, b = 1,')
  end)
end)

spec('binop assignment', function()
  assert.are.equal('nc', unit.Assignment('a ??= 1').op.tag)
  assert.are.equal('or', unit.Assignment('a |= 1').op.tag)
  assert.are.equal('and', unit.Assignment('a &= 1').op.tag)
  assert.are.equal('bor', unit.Assignment('a .|= 1').op.tag)
  assert.are.equal('bxor', unit.Assignment('a .~= 1').op.tag)
  assert.are.equal('band', unit.Assignment('a .&= 1').op.tag)
  assert.are.equal('lshift', unit.Assignment('a .<<= 1').op.tag)
  assert.are.equal('rshift', unit.Assignment('a .>>= 1').op.tag)
  assert.are.equal('concat', unit.Assignment('a ..= 1').op.tag)
  assert.are.equal('add', unit.Assignment('a += 1').op.tag)
  assert.are.equal('sub', unit.Assignment('a -= 1').op.tag)
  assert.are.equal('mult', unit.Assignment('a *= 1').op.tag)
  assert.are.equal('div', unit.Assignment('a /= 1').op.tag)
  assert.are.equal('intdiv', unit.Assignment('a //= 1').op.tag)
  assert.are.equal('mod', unit.Assignment('a %= 1').op.tag)
  assert.are.equal('exp', unit.Assignment('a ^= 1').op.tag)
  assert.has_subtable({
    idList = { { value = 'a' } },
    op = { tag = 'add' },
    exprList = { { value = '3' } },
  }, unit.Assignment(
    'a += 3'
  ))
end)

spec('binop assignment blacklist', function()
  assert.has_error(function()
    unit.Assignment('a >>= 1')
  end)
  assert.has_error(function()
    unit.Assignment('a ?= 1')
  end)
  assert.has_error(function()
    unit.Assignment('a === 1')
  end)
  assert.has_error(function()
    unit.Assignment('a ~== 1')
  end)
  assert.has_error(function()
    unit.Assignment('a <== 1')
  end)
  assert.has_error(function()
    unit.Assignment('a >== 1')
  end)
  assert.has_error(function()
    unit.Assignment('a <= 1')
  end)
  assert.has_error(function()
    unit.Assignment('a >= 1')
  end)
end)
