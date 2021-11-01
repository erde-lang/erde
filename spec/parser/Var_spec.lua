local unit = require('erde.parser.unit')

spec('var rule', function()
  assert.are.equal('Var', unit.Var('local a').rule)
end)

spec('local var', function()
  assert.has_subtable({
    variant = 'local',
    nameList = { 'abc' },
  }, unit.Var(
    'local abc'
  ))
  assert.has_subtable({
    variant = 'local',
    nameList = { 'abc' },
    exprList = { { value = '2' } },
  }, unit.Var(
    'local abc = 2'
  ))
end)

spec('global var', function()
  assert.has_subtable({
    variant = 'global',
    nameList = { 'abc' },
  }, unit.Var(
    'global abc'
  ))
  assert.has_subtable({
    variant = 'global',
    nameList = { 'abc' },
    exprList = { { value = '2' } },
  }, unit.Var(
    'global abc = 2'
  ))
end)

spec('multiple var', function()
  assert.has_subtable({
    nameList = { 'a', 'b' },
  }, unit.Var('local a, b'))
  assert.has_subtable({
    exprList = {
      { value = '1' },
      { value = '2' },
    },
  }, unit.Var(
    'local a, b = 1, 2'
  ))
  assert.has_error(function()
    unit.Var('local a,')
  end)
  assert.has_error(function()
    unit.Var('local a = 1,')
  end)
end)
