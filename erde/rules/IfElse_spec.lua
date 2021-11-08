-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('IfElse.parse', function()
  spec('rule', function()
    assert.are.equal('IfElse', parse.IfElse('if true {}').rule)
  end)

  spec('if', function()
    assert.has_subtable({
      ifNode = {
        cond = { value = 'true' },
        body = {},
      },
    }, parse.IfElse(
      'if true {}'
    ))
  end)

  spec('if + elseif', function()
    assert.has_subtable({
      ifNode = {},
      elseifNodes = {
        { cond = { value = 'true' } },
      },
    }, parse.IfElse(
      'if false {} elseif true {}'
    ))
    assert.has_subtable({
      ifNode = {},
      elseifNodes = {
        { cond = { value = 'false' } },
        { cond = { value = 'true' } },
      },
    }, parse.IfElse(
      'if false {} elseif false {} elseif true {}'
    ))
  end)

  spec('if + else', function()
    assert.has_subtable({
      ifNode = {},
      elseNode = { body = {} },
    }, parse.IfElse(
      'if true {} else {}'
    ))
  end)

  spec('if + elseif + else', function()
    assert.has_no.errors(function()
      parse.IfElse('if false {} elseif false {} else {}')
    end)
    assert.has_no.errors(function()
      parse.IfElse('if false {} elseif false {} elseif true {} else {}')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('IfElse.compile', function()
  spec('if', function()
    assert.run(1, compile.Block('if true { return 1 }'))
    assert.run(nil, compile.Block('if false { return 1 }'))
  end)

  spec('if + elseif', function()
    assert.run(
      2,
      compile.Block([[
        if false {
          return 1
        } elseif true {
          return 2
        }
      ]])
    )
  end)

  spec('if + else', function()
    assert.run(
      2,
      compile.Block([[
        if false {
          return 1
        } else {
          return 2
        }
      ]])
    )
  end)

  spec('if + elseif + else', function()
    assert.run(
      2,
      compile.Block([[
        if false {
          return 1
        } elseif true {
          return 2
        } else {
          return 3
        }
      ]])
    )
    assert.run(
      3,
      compile.Block([[
        if false {
          return 1
        } elseif false {
          return 2
        } else {
          return 3
        }
      ]])
    )
  end)
end)
