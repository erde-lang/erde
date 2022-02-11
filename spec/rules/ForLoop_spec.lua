-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('ForLoop.parse', function()
  spec('numeric for loop', function()
    assert.subtable({
      variant = 'numeric',
      name = { value = 'i' },
      parts = {
        { value = '1' },
        { value = '2' },
      },
    }, parse.ForLoop('for i = 1, 2 {}'))
    assert.subtable({
      variant = 'numeric',
      name = { value = 'i' },
      parts = {
        { value = '1' },
        { value = '2' },
        { value = '3' },
      },
    }, parse.ForLoop('for i = 1, 2, 3 {}'))
    assert.has_error(function()
      parse.ForLoop('for i = 1 {}')
    end)
    assert.has_error(function()
      parse.ForLoop('for i = 1, 2, 3, 4 {}')
    end)
  end)

  spec('generic for loop', function()
    assert.subtable({
      variant = 'generic',
      varList = { { value = 'a' } },
      exprList = { { value = '1' } },
    }, parse.ForLoop('for a in 1 {}'))
    assert.subtable({
      variant = 'generic',
      varList = { { value = 'a' }, { value = 'b' } },
      exprList = { { value = '1' } },
    }, parse.ForLoop('for a, b in 1 {}'))
    assert.subtable({
      variant = 'generic',
      varList = { { value = 'a' } },
      exprList = {
        { value = '1' },
        { value = '2' },
      },
    }, parse.ForLoop('for a in 1, 2 {}'))
    assert.subtable({
      variant = 'generic',
      varList = { { value = 'a' }, { value = 'b' } },
      exprList = {
        { value = '1' },
        { value = '2' },
      },
    }, parse.ForLoop('for a, b in 1, 2 {}'))
    assert.subtable({
      variant = 'generic',
      varList = { { ruleName = 'Destructure' } },
    }, parse.ForLoop('for [a, b] in myiter() {}'))
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
    assert.run(
      11,
      compile.Block([[
        local x = 0
        for i, [a, b] in ipairs({{5, 6}}) {
          x += a + b
        }
        return x
      ]])
    )
  end)
end)
