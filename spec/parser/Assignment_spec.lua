local unit = require('erde.parser.unit')

spec('valid assignment', function()
  assert.has_subtable({
    tag = 'TAG_ASSIGNMENT',
    name = 'myvar',
    expr = {
      tag = 'TAG_NUMBER',
      value = '3',
    },
  }, unit.Assignment(
    'myvar = 3'
  ))
  assert.has_subtable({
    tag = 'TAG_ASSIGNMENT',
    name = 'myvar',
    opTag = 'TAG_ADD',
    expr = {
      tag = 'TAG_NUMBER',
      value = '3',
    },
  }, unit.Assignment(
    'myvar += 3'
  ))
end)

spec('invalid assignment', function()
  assert.has_error(function()
    unit.Assignment('myvar')
  end)
  assert.has_error(function()
    unit.Assignment('myvar +')
  end)
end)

spec('binop assignment', function()
  assert.are.equal('TAG_PIPE', unit.Assignment('x >>= 1').opTag)
  assert.are.equal('TAG_NC', unit.Assignment('x ??= 1').opTag)
  assert.are.equal('TAG_OR', unit.Assignment('x |= 1').opTag)
  assert.are.equal('TAG_AND', unit.Assignment('x &= 1').opTag)
  assert.are.equal('TAG_BOR', unit.Assignment('x .|= 1').opTag)
  assert.are.equal('TAG_BXOR', unit.Assignment('x .~= 1').opTag)
  assert.are.equal('TAG_BAND', unit.Assignment('x .&= 1').opTag)
  assert.are.equal('TAG_LSHIFT', unit.Assignment('x .<<= 1').opTag)
  assert.are.equal('TAG_RSHIFT', unit.Assignment('x .>>= 1').opTag)
  assert.are.equal('TAG_CONCAT', unit.Assignment('x ..= 1').opTag)
  assert.are.equal('TAG_ADD', unit.Assignment('x += 1').opTag)
  assert.are.equal('TAG_SUB', unit.Assignment('x -= 1').opTag)
  assert.are.equal('TAG_MULT', unit.Assignment('x *= 1').opTag)
  assert.are.equal('TAG_DIV', unit.Assignment('x /= 1').opTag)
  assert.are.equal('TAG_INTDIV', unit.Assignment('x //= 1').opTag)
  assert.are.equal('TAG_MOD', unit.Assignment('x %= 1').opTag)
  assert.are.equal('TAG_EXP', unit.Assignment('x ^= 1').opTag)
end)

spec('binop assignment blacklist', function()
  assert.has_error(function()
    unit.Assignment('x ?= 1')
  end)
  assert.has_error(function()
    unit.Assignment('x === 1')
  end)
  assert.has_error(function()
    unit.Assignment('x ~== 1')
  end)
  assert.has_error(function()
    unit.Assignment('x <== 1')
  end)
  assert.has_error(function()
    unit.Assignment('x >== 1')
  end)
  assert.has_error(function()
    unit.Assignment('x <= 1')
  end)
  assert.has_error(function()
    unit.Assignment('x >= 1')
  end)
end)
