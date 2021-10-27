local unit = require('erde.parser.unit')

spec('function rules', function()
  assert.are.equal('Function', unit.Function('function a() {}').rule)
end)

spec('valid function', function()
  assert.has_subtable({
    variant = 'local',
    isMethod = false,
    names = { 'a' },
  }, unit.Function(
    'local function a() {}'
  ))
  assert.has_subtable({
    variant = 'global',
    isMethod = false,
    names = { 'hello' },
  }, unit.Function(
    'function hello() {}'
  ))
  assert.has_subtable({
    variant = 'global',
    isMethod = false,
    names = { 'hello', 'world' },
  }, unit.Function(
    'function hello.world() {}'
  ))
  assert.has_subtable({
    variant = 'global',
    isMethod = true,
    names = { 'hello', 'world' },
  }, unit.Function(
    'function hello:world() {}'
  ))
end)

spec('invalid function', function()
  assert.has_error(function()
    unit.ArrowFunction('global function a() {}')
  end)
  assert.has_error(function()
    unit.ArrowFunction('function a {}')
  end)
  assert.has_error(function()
    unit.ArrowFunction('function() {}')
  end)
end)

spec('valid function call', function()
  assert.has_subtable({
    base = { value = 'hello' },
    { variant = 'parens', optional = false, value = {} },
  }, unit.FunctionCall(
    'hello()'
  ))
  assert.has_subtable({
    base = { value = 'hello' },
    { variant = 'dot', optional = false, value = 'world' },
    { variant = 'parens', optional = true },
  }, unit.FunctionCall(
    'hello.world?()'
  ))
  assert.has_subtable({
    base = { value = 'hello' },
    { variant = 'colon', value = 'world' },
    { variant = 'parens', optional = false },
  }, unit.FunctionCall(
    'hello:world()'
  ))
end)

spec('invalid function call', function()
  assert.has_error(function()
    unit.FunctionCall('hello:world')
  end)
  assert.has_error(function()
    unit.FunctionCall('hello?.()')
  end)
end)
