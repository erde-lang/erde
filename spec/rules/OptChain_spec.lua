-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('OptChain.parse', function()
  spec('ruleNames', function()
    assert.are.equal('OptChain', parse.OptChain('a.b').ruleName)
    assert.are.equal('OptChain', parse.FunctionCall('a()').ruleName)
    assert.are.equal('OptChain', parse.Id('a.b').ruleName)
  end)

  spec('optchain base', function()
    assert.are.equal('a', parse.OptChain('a'))
    assert.subtable({
      base = 'a',
    }, parse.OptChain('a.b'))
    assert.subtable({
      base = { ruleName = 'Expr' },
    }, parse.OptChain(
      '(1 + 2).a'
    ))
    assert.has_error(function()
      parse.OptChain('1.b')
    end)
  end)

  spec('optchain dotIndex', function()
    assert.subtable({
      {
        optional = false,
        variant = 'dotIndex',
        value = 'b',
      },
    }, parse.OptChain(
      'a.b'
    ))
    assert.subtable({
      {
        optional = true,
        variant = 'dotIndex',
      },
    }, parse.OptChain(
      'a?.b'
    ))
  end)

  spec('optchain bracketIndex', function()
    assert.subtable({
      {
        optional = false,
        variant = 'bracketIndex',
        value = { op = { token = '+' } },
      },
    }, parse.OptChain(
      'a[2 + 3]'
    ))
    assert.subtable({
      {
        optional = true,
        variant = 'bracketIndex',
      },
    }, parse.OptChain(
      'a?[2 + 3]'
    ))
  end)

  spec('optchain functionCall', function()
    assert.subtable({
      {
        optional = false,
        variant = 'functionCall',
        value = {
          { value = '1' },
          { value = '2' },
        },
      },
    }, parse.OptChain(
      'a(1, 2)'
    ))
    assert.subtable({
      {
        optional = true,
        variant = 'functionCall',
      },
    }, parse.OptChain(
      'a?(1, 2)'
    ))
    assert.are.equal(0, #parse.OptChain('a()')[1].value)
  end)

  spec('optchain method', function()
    assert.subtable({
      {
        optional = false,
        variant = 'method',
        value = 'b',
      },
      { variant = 'functionCall' },
    }, parse.OptChain(
      'a:b(1, 2)'
    ))
    assert.subtable({
      {
        optional = true,
        variant = 'method',
        value = 'b',
      },
      { variant = 'functionCall' },
    }, parse.OptChain(
      'a?:b(1, 2)'
    ))
    assert.has_no.errors(function()
      parse.OptChain('a:b().c')
    end)
    assert.has_error(function()
      parse.OptChain('a:b')
    end)
    assert.has_error(function()
      parse.OptChain('a:b.c()')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('OptChain.compile', function()
  spec('optchain base', function()
    assert.eval(1, compile.OptChain('({ x = 1 }).x'))
  end)

  spec('optchain dotIndex', function()
    assert.run(
      1,
      compile.Block([[
        local a = { b = 1 }
        return a.b
      ]])
    )
    assert.run(
      nil,
      compile.Block([[
        local a = {}
        return a?.b
      ]])
    )
  end)

  spec('optchain bracketIndex', function()
    assert.run(
      1,
      compile.Block([[
        local a = { [5] = 1 }
        return a[2 + 3]
      ]])
    )
    assert.run(
      nil,
      compile.Block([[
        local a = {}
        return a?[2 + 3]
      ]])
    )
  end)

  spec('optchain functionCall', function()
    assert.run(
      3,
      compile.Block([[
        local a = (x, y) -> x + y
        return a(1, 2)
      ]])
    )
    assert.run(
      nil,
      compile.Block([[
        local a
        return a?(1, 2)
      ]])
    )
  end)

  spec('optchain method', function()
    assert.run(
      3,
      compile.Block([[
        local a = {
          b = (self, x) -> self.c + x,
          c = 1,
        }
        return a:b(2)
      ]])
    )
    assert.run(
      nil,
      compile.Block([[
        local a
        return a?:b(1, 2)
      ]])
    )
  end)
end)
