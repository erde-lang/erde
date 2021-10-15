local unit = require('erde.parser.unit')

spec('valid assignment', function()
  assert.has_subtable({
    tag = 'TAG_ASSIGNMENT',
    name = 'myvar',
    expr = {
      tag = 'TAG_NUMBER',
      value = '3',
    },
  }, unit.assignment(
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
  }, unit.assignment(
    'myvar += 3'
  ))
end)

spec('invalid assignment', function()
  assert.has_error(function()
    unit.assignment('myvar')
  end)
  assert.has_error(function()
    unit.assignment('myvar +')
  end)
end)

spec('binop assignment', function()
  assert.are.equal('TAG_PIPE', unit.assignment('x >>= 1').opTag)
  assert.are.equal('TAG_NC', unit.assignment('x ??= 1').opTag)
  assert.are.equal('TAG_OR', unit.assignment('x |= 1').opTag)
  assert.are.equal('TAG_AND', unit.assignment('x &= 1').opTag)
  assert.are.equal('TAG_BOR', unit.assignment('x .|= 1').opTag)
  assert.are.equal('TAG_BXOR', unit.assignment('x .~= 1').opTag)
  assert.are.equal('TAG_BAND', unit.assignment('x .&= 1').opTag)
  assert.are.equal('TAG_LSHIFT', unit.assignment('x .<<= 1').opTag)
  assert.are.equal('TAG_RSHIFT', unit.assignment('x .>>= 1').opTag)
  assert.are.equal('TAG_CONCAT', unit.assignment('x ..= 1').opTag)
  assert.are.equal('TAG_ADD', unit.assignment('x += 1').opTag)
  assert.are.equal('TAG_SUB', unit.assignment('x -= 1').opTag)
  assert.are.equal('TAG_MULT', unit.assignment('x *= 1').opTag)
  assert.are.equal('TAG_DIV', unit.assignment('x /= 1').opTag)
  assert.are.equal('TAG_INTDIV', unit.assignment('x //= 1').opTag)
  assert.are.equal('TAG_MOD', unit.assignment('x %= 1').opTag)
  assert.are.equal('TAG_EXP', unit.assignment('x ^= 1').opTag)
end)

spec('binop assignment blacklist', function()
  assert.has_error(function()
    unit.assignment('x ?= 1')
  end)
  assert.has_error(function()
    unit.assignment('x === 1')
  end)
  assert.has_error(function()
    unit.assignment('x ~== 1')
  end)
  assert.has_error(function()
    unit.assignment('x <== 1')
  end)
  assert.has_error(function()
    unit.assignment('x >== 1')
  end)
  assert.has_error(function()
    unit.assignment('x <= 1')
  end)
  assert.has_error(function()
    unit.assignment('x >= 1')
  end)
end)
