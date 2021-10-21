local unit = require('erde.parser.unit')

spec('local var', function()
  assert.has_subtable({
    tag = 'TAG_LOCAL_VAR',
    name = 'abc',
  }, unit.Var(
    'local abc'
  ))
  assert.has_subtable({
    tag = 'TAG_LOCAL_VAR',
    name = 'abc',
    initValue = {
      tag = 'TAG_NUMBER',
      value = '2',
    },
  }, unit.Var(
    'local abc = 2'
  ))
end)

spec('global var', function()
  assert.has_subtable({
    tag = 'TAG_GLOBAL_VAR',
    name = 'abc',
  }, unit.Var(
    'global abc'
  ))
  assert.has_subtable({
    tag = 'TAG_GLOBAL_VAR',
    name = 'abc',
    initValue = {
      tag = 'TAG_NUMBER',
      value = '2',
    },
  }, unit.Var(
    'global abc = 2'
  ))
end)
