local unit = require('erde.parser.unit')

spec('valid arrow function', function()
  assert.has_subtable({
    tag = 'TAG_ARROW_FUNCTION',
    variant = 'SKINNY',
    body = {
      { tag = 'TAG_RETURN' },
    },
  }, unit.ArrowFunction(
    '() -> { return 1 }'
  ))
  assert.has_subtable({
    tag = 'TAG_ARROW_FUNCTION',
    variant = 'SKINNY',
    returns = {
      { value = '1' },
    },
  }, unit.ArrowFunction(
    '() -> 1'
  ))
  assert.has_subtable({
    tag = 'TAG_ARROW_FUNCTION',
    variant = 'SKINNY',
    returns = {
      { value = '1' },
      { value = '2' },
    },
  }, unit.ArrowFunction(
    '() -> 1, 2'
  ))
  assert.has_subtable({
    tag = 'TAG_ARROW_FUNCTION',
    variant = 'FAT',
  }, unit.ArrowFunction(
    '() => { return 1 }'
  ))
end)

spec('invalid arrow function', function()
  assert.has_error(function()
    unit.ArrowFunction('-> {}')
  end)
  assert.has_error(function()
    unit.ArrowFunction('() ~> {}')
  end)
  assert.has_error(function()
    unit.ArrowFunction('() ~> 1,')
  end)
  assert.has_error(function()
    unit.ArrowFunction('() ~> ,1')
  end)
end)

spec('valid function', function()
  assert.has_subtable({
    tag = 'TAG_LOCAL_FUNCTION',
    name = { value = 'a' },
  }, unit.Function(
    'local function a() {}'
  ))
  assert.has_subtable({
    tag = 'TAG_FUNCTION',
    name = { value = 'hello' },
  }, unit.Function(
    'function hello() {}'
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
    tag = 'TAG_FUNCTION_CALL',
    base = { value = 'hello' },
    { variant = 'FUNCTION_CALL', optional = false, value = {} },
  }, unit.FunctionCall(
    'hello()'
  ))
  assert.has_subtable({
    tag = 'TAG_FUNCTION_CALL',
    base = { value = 'hello' },
    { variant = 'DOT_INDEX', optional = false, value = 'world' },
    { variant = 'FUNCTION_CALL', optional = true },
  }, unit.FunctionCall(
    'hello.world?()'
  ))
  assert.has_subtable({
    tag = 'TAG_FUNCTION_CALL',
    base = { value = 'hello' },
    { variant = 'METHOD_CALL', value = 'world' },
    { variant = 'FUNCTION_CALL', optional = false },
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
