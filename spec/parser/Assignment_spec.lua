local unit = require('erde.parser.unit')

spec('valid assignment', function()
  assert.has_subtable({
    rule = 'Assignment',
    name = 'myvar',
    expr = {
      rule = 'Number',
      value = '3',
    },
  }, unit.Assignment(
    'myvar = 3'
  ))
  assert.has_subtable({
    rule = 'Assignment',
    name = 'myvar',
    op = 'add',
    expr = {
      rule = 'Number',
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
  assert.are.equal('pipe', unit.Assignment('x >>= 1').op)
  assert.are.equal('nc', unit.Assignment('x ??= 1').op)
  assert.are.equal('or', unit.Assignment('x |= 1').op)
  assert.are.equal('and', unit.Assignment('x &= 1').op)
  assert.are.equal('bor', unit.Assignment('x .|= 1').op)
  assert.are.equal('bxor', unit.Assignment('x .~= 1').op)
  assert.are.equal('band', unit.Assignment('x .&= 1').op)
  assert.are.equal('lshift', unit.Assignment('x .<<= 1').op)
  assert.are.equal('rshift', unit.Assignment('x .>>= 1').op)
  assert.are.equal('concat', unit.Assignment('x ..= 1').op)
  assert.are.equal('add', unit.Assignment('x += 1').op)
  assert.are.equal('sub', unit.Assignment('x -= 1').op)
  assert.are.equal('mult', unit.Assignment('x *= 1').op)
  assert.are.equal('div', unit.Assignment('x /= 1').op)
  assert.are.equal('intdiv', unit.Assignment('x //= 1').op)
  assert.are.equal('mod', unit.Assignment('x %= 1').op)
  assert.are.equal('exp', unit.Assignment('x ^= 1').op)
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
