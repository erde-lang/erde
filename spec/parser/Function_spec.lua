local unit = require('erde.parser.unit')

spec('function rules', function()
  assert.are.equal('Function', unit.Function('function a() {}').rule)
end)

spec('local function', function()
  assert.has_subtable({
    variant = 'local',
    names = { 'a' },
  }, unit.Function(
    'local function a() {}'
  ))
  assert.has_error(function()
    unit.ArrowFunction('local function() {}')
  end)
end)

spec('global function', function()
  assert.has_subtable({
    variant = 'global',
    names = { 'a' },
  }, unit.Function(
    'function a() {}'
  ))
  assert.has_error(function()
    unit.ArrowFunction('function() {}')
  end)
  assert.has_error(function()
    unit.ArrowFunction('global function a() {}')
  end)
end)

spec('method function', function()
  assert.has_subtable({
    isMethod = true,
    names = { 'a', 'b' },
  }, unit.Function(
    'function a:b() {}'
  ))
  assert.has_error(function()
    unit.FunctionCall('function a:b.c() {}')
  end)
end)
