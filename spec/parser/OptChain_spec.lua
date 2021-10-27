local unit = require('erde.parser.unit')

spec('optchain rules', function()
  assert.are.equal('OptChain', unit.OptChain('a.b').rule)
  assert.are.equal('OptChain', unit.FunctionCall('a()').rule)
  assert.are.equal('OptChain', unit.Id('a.b').rule)
end)

spec('optchain base', function()
  assert.has_subtable({
    base = { value = 'a' },
  }, unit.OptChain('a'))
  assert.has_subtable({
    base = { value = 'a' },
  }, unit.OptChain('a.b'))
  assert.has_subtable({
    base = { rule = 'Expr' },
  }, unit.OptChain(
    '(1 + 2).a'
  ))
  assert.has_error(function()
    unit.OptChain('1.b')
  end)
  assert.has_error(function()
    unit.OptChain('a.(1 + 2)')
  end)
end)

spec('optchain dotIndex', function()
  assert.has_subtable({
    {
      optional = false,
      variant = 'dotIndex',
      value = 'b',
    },
  }, unit.OptChain(
    'a.b'
  ))
  assert.has_subtable({
    {
      optional = true,
      variant = 'dotIndex',
    },
  }, unit.OptChain(
    'a?.b'
  ))
end)

spec('optchain bracketIndex', function()
  assert.has_subtable({
    {
      optional = false,
      variant = 'bracketIndex',
      value = { op = { tag = 'add' } },
    },
  }, unit.OptChain(
    'a[2 + 3]'
  ))
  assert.has_subtable({
    {
      optional = true,
      variant = 'bracketIndex',
    },
  }, unit.OptChain(
    'a?[2 + 3]'
  ))
end)

spec('optchain params', function()
  assert.has_subtable({
    {
      optional = false,
      variant = 'params',
      value = {
        { value = '1' },
        { value = '2' },
      },
    },
  }, unit.OptChain(
    'a(1, 2)'
  ))
  assert.has_subtable({
    {
      optional = true,
      variant = 'params',
    },
  }, unit.OptChain(
    'a?(1, 2)'
  ))
  assert.are.equal(0, #unit.OptChain('a()')[1].value)
end)

spec('optchain method', function()
  assert.has_subtable({
    {
      optional = false,
      variant = 'method',
      value = 'b',
    },
    { variant = 'params' },
  }, unit.OptChain(
    'a:b(1, 2)'
  ))
  assert.has_subtable({
    {
      optional = true,
      variant = 'method',
      value = 'b',
    },
    { variant = 'params' },
  }, unit.OptChain(
    'a?:b(1, 2)'
  ))
  assert.has_no.errors(function()
    unit.OptChain('a:b().c')
  end)
  assert.has_error(function()
    unit.OptChain('a:b')
  end)
  assert.has_error(function()
    unit.OptChain('a:b.c()')
  end)
end)

spec('function call', function()
  assert.has_error(function()
    unit.FunctionCall('a')
  end)
  assert.has_error(function()
    unit.FunctionCall('a.b')
  end)
  assert.has_no.errors(function()
    unit.FunctionCall('hello()')
  end)
end)

spec('id', function()
  assert.has_error(function()
    unit.Id('a.b()')
  end)
  assert.has_no.errors(function()
    unit.Id('a.b')
  end)
end)
