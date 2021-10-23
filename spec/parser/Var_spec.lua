local unit = require('erde.parser.unit')

spec('local var', function()
  assert.has_subtable({
    rule = 'Var',
    variant = 'local',
    name = 'abc',
  }, unit.Var(
    'local abc'
  ))
  assert.has_subtable({
    rule = 'Var',
    variant = 'local',
    name = 'abc',
    initValue = {
      rule = 'Number',
      value = '2',
    },
  }, unit.Var(
    'local abc = 2'
  ))
end)

spec('global var', function()
  assert.has_subtable({
    rule = 'Var',
    variant = 'global',
    name = 'abc',
  }, unit.Var(
    'global abc'
  ))
  assert.has_subtable({
    rule = 'Var',
    variant = 'global',
    name = 'abc',
    initValue = {
      rule = 'Number',
      value = '2',
    },
  }, unit.Var(
    'global abc = 2'
  ))
end)
