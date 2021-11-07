-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('ForLoop.parse', function()
  spec('rule', function()
    assert.are.equal('ForLoop', parse.ForLoop('for i = 1, 2 {}').rule)
  end)

  spec('numeric for loop', function()
    assert.has_subtable({
      variant = 'numeric',
      name = 'i',
      var = { value = '1' },
      limit = { value = '2' },
    }, parse.ForLoop(
      'for i = 1, 2 {}'
    ))
    assert.has_subtable({
      variant = 'numeric',
      name = 'i',
      var = { value = '1' },
      limit = { value = '2' },
      step = { value = '3' },
    }, parse.ForLoop(
      'for i = 1, 2, 3 {}'
    ))
    assert.has_error(function()
      parse.ForLoop('for i = 1 {}')
    end)
    assert.has_error(function()
      parse.ForLoop('for i = 1, 2, 3, 4 {}')
    end)
  end)

  spec('generic for loop', function()
    assert.has_subtable({
      variant = 'generic',
      nameList = { 'a' },
      exprList = { { value = '1' } },
    }, parse.ForLoop(
      'for a in 1 {}'
    ))
    assert.has_subtable({
      variant = 'generic',
      nameList = { 'a', 'b' },
      exprList = { { value = '1' } },
    }, parse.ForLoop(
      'for a, b in 1 {}'
    ))
    assert.has_subtable({
      variant = 'generic',
      nameList = { 'a' },
      exprList = {
        { value = '1' },
        { value = '2' },
      },
    }, parse.ForLoop(
      'for a in 1, 2 {}'
    ))
    assert.has_subtable({
      variant = 'generic',
      nameList = { 'a', 'b' },
      exprList = {
        { value = '1' },
        { value = '2' },
      },
    }, parse.ForLoop(
      'for a, b in 1, 2 {}'
    ))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('ForLoop.compile', function()
  spec('numeric for', function()
    assert.run(
      10,
      compile.Block([[
        local x = 0
        for i = 1, 4 {
          x += i
        }
        return x
      ]])
    )
    assert.run(
      4,
      compile.Block([[
        local x = 0
        for i = 1, 4, 2 {
          x += i
        }
        return x
      ]])
    )
  end)
  spec('generic for', function()
    assert.run(
      10,
      compile.Block([[
        local x = 0
        for i, value in ipairs({ 1, 2, 8, 1 }) {
          x += i
        }
        return x
      ]])
    )
    assert.run(
      12,
      compile.Block([[
        local x = 0
        for i, value in ipairs({ 1, 2, 8, 1 }) {
          x += value
        }
        return x
      ]])
    )
  end)
end)
