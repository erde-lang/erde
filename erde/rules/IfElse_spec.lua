-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('IfElse.parse', function()
  spec('rule', function()
    assert.are.equal('IfElse', unit.IfElse('if true {}').rule)
  end)

  spec('if', function()
    assert.has_subtable({
      ifNode = {
        cond = { value = 'true' },
        body = {},
      },
    }, unit.IfElse(
      'if true {}'
    ))
  end)

  spec('if + elseif', function()
    assert.has_subtable({
      ifNode = {},
      elseifNodes = {
        { cond = { value = 'true' } },
      },
    }, unit.IfElse(
      'if false {} elseif true {}'
    ))
    assert.has_subtable({
      ifNode = {},
      elseifNodes = {
        { cond = { value = 'false' } },
        { cond = { value = 'true' } },
      },
    }, unit.IfElse(
      'if false {} elseif false {} elseif true {}'
    ))
  end)

  spec('if + else', function()
    assert.has_subtable({
      ifNode = {},
      elseNode = { body = {} },
    }, unit.IfElse(
      'if true {} else {}'
    ))
  end)

  spec('if + elseif + else', function()
    assert.has_no.errors(function()
      unit.IfElse('if false {} elseif false {} else {}')
    end)
    assert.has_no.errors(function()
      unit.IfElse('if false {} elseif false {} elseif true {} else {}')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('IfElse.compile', function()
  -- TODO
end)
