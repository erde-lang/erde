local unit = require('erde.parser.unit')

spec('valid if else', function()
  assert.has_subtable({
    rule = 'IfElse',
    ifNode = {
      cond = {
        op = 'gt',
        { value = '2' },
        { value = '1' },
      },
    },
  }, unit.IfElse(
    'if 2 > 1 {}'
  ))
  assert.has_subtable({
    rule = 'IfElse',
    elseifNodes = {
      {
        cond = {
          op = 'gt',
          { value = '3' },
          { value = '1' },
        },
      },
    },
  }, unit.IfElse(
    'if 2 > 1 {} elseif 3 > 1 {}'
  ))
  assert.has_subtable({
    rule = 'IfElse',
    elseifNodes = {
      {
        cond = {
          op = 'gt',
          { value = '3' },
          { value = '1' },
        },
      },
      {
        cond = {
          op = 'gt',
          { value = '4' },
          { value = '1' },
        },
      },
    },
  }, unit.IfElse(
    'if 2 > 1 {} elseif 3 > 1 {} elseif 4 > 1 {}'
  ))
  assert.has_subtable({
    rule = 'IfElse',
    elseNode = {},
  }, unit.IfElse(
    'if 2 > 1 {} elseif 3 > 1 {} else {}'
  ))
  assert.has_subtable({
    rule = 'IfElse',
    elseNode = {},
  }, unit.IfElse(
    'if 2 > 1 {} else {}'
  ))
end)

spec('invalid if else', function()
  assert.has_error(function()
    unit.IfElse('if {}')
  end)
  assert.has_error(function()
    unit.IfElse('if 2 > 1 {')
  end)
  assert.has_error(function()
    unit.IfElse('if 2 > 1 {} elseif {}')
  end)
  assert.has_error(function()
    unit.IfElse('if 2 > 1 {} else 2 > 1 {}')
  end)
  assert.has_error(function()
    unit.IfElse('elseif 2 > 1 {}')
  end)
  assert.has_error(function()
    unit.IfElse('else {}')
  end)
end)
