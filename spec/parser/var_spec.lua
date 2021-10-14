local unit = require('erde.parser.unit')

spec('local var', function()
  assert.is_nil(unit.var('localabc'))
  assert.has_subtable({
    tag = 'TAG_LOCAL_VAR',
    name = 'abc',
  }, unit.var(
    'local abc'
  ))
  assert.has_subtable({
    tag = 'TAG_LOCAL_VAR',
    name = 'abc',
    initValue = {
      tag = 'TAG_NUMBER',
      value = '2',
    },
  }, unit.var(
    'local abc = 2'
  ))
end)

spec('global var', function()
  assert.is_nil(unit.var('globalabc'))
  assert.has_subtable({
    tag = 'TAG_GLOBAL_VAR',
    name = 'abc',
  }, unit.var(
    'global abc'
  ))
  assert.has_subtable({
    tag = 'TAG_GLOBAL_VAR',
    name = 'abc',
    initValue = {
      tag = 'TAG_NUMBER',
      value = '2',
    },
  }, unit.var(
    'global abc = 2'
  ))
end)
