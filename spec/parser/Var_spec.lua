local unit = require('erde.parser.unit')

spec('var rule', function()
  assert.are.equal('Var', unit.Var('local a').rule)
end)

spec('local var', function()
  assert.has_subtable({
    variant = 'local',
    name = 'abc',
  }, unit.Var(
    'local abc'
  ))
  assert.has_subtable({
    variant = 'local',
    name = 'abc',
    initValue = { value = '2' },
  }, unit.Var(
    'local abc = 2'
  ))
end)

spec('global var', function()
  assert.has_subtable({
    variant = 'global',
    name = 'abc',
  }, unit.Var(
    'global abc'
  ))
  assert.has_subtable({
    variant = 'global',
    name = 'abc',
    initValue = { value = '2' },
  }, unit.Var(
    'global abc = 2'
  ))
end)
