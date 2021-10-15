local unit = require('erde.parser.unit')

spec('valid if else', function()
  assert.has_subtable({
    tag = 'TAG_IF_ELSE',
    ifNode = {
      cond = {
        tag = 'TAG_GT',
        { value = '2' },
        { value = '1' },
      },
    },
  }, unit.ifElse(
    'if 2 > 1 {}'
  ))
  assert.has_subtable({
    tag = 'TAG_IF_ELSE',
    elseifNodes = {
      {
        cond = {
          tag = 'TAG_GT',
          { value = '3' },
          { value = '1' },
        },
      },
    },
  }, unit.ifElse(
    'if 2 > 1 {} elseif 3 > 1 {}'
  ))
  assert.has_subtable({
    tag = 'TAG_IF_ELSE',
    elseifNodes = {
      {
        cond = {
          tag = 'TAG_GT',
          { value = '3' },
          { value = '1' },
        },
      },
      {
        cond = {
          tag = 'TAG_GT',
          { value = '4' },
          { value = '1' },
        },
      },
    },
  }, unit.ifElse(
    'if 2 > 1 {} elseif 3 > 1 {} elseif 4 > 1 {}'
  ))
  assert.has_subtable({
    tag = 'TAG_IF_ELSE',
    elseNode = {},
  }, unit.ifElse(
    'if 2 > 1 {} elseif 3 > 1 {} else {}'
  ))
  assert.has_subtable({
    tag = 'TAG_IF_ELSE',
    elseNode = {},
  }, unit.ifElse(
    'if 2 > 1 {} else {}'
  ))
end)

spec('invalid if else', function()
  assert.has_error(function()
    unit.ifElse('if {}')
  end)
  assert.has_error(function()
    unit.ifElse('if 2 > 1 {')
  end)
  assert.has_error(function()
    unit.ifElse('if 2 > 1 {} elseif {}')
  end)
  assert.has_error(function()
    unit.ifElse('if 2 > 1 {} else 2 > 1 {}')
  end)
  assert.has_error(function()
    unit.ifElse('elseif 2 > 1 {}')
  end)
  assert.has_error(function()
    unit.ifElse('else {}')
  end)
end)
