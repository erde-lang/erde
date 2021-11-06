-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('OptChain.parse', function()
  spec('rules', function()
    assert.are.equal('OptChain', parse.OptChain('a.b').rule)
    assert.are.equal('OptChain', parse.FunctionCall('a()').rule)
    assert.are.equal('OptChain', parse.Id('a.b').rule)
  end)

  spec('optchain base', function()
    assert.has_subtable({
      value = 'a',
    }, parse.OptChain('a'))
    assert.has_subtable({
      base = { value = 'a' },
    }, parse.OptChain(
      'a.b'
    ))
    assert.has_subtable({
      base = { rule = 'Expr' },
    }, parse.OptChain(
      '(1 + 2).a'
    ))
    assert.has_error(function()
      parse.OptChain('1.b')
    end)
  end)

  spec('optchain dotIndex', function()
    assert.has_subtable({
      {
        optional = false,
        variant = 'dotIndex',
        value = 'b',
      },
    }, parse.OptChain(
      'a.b'
    ))
    assert.has_subtable({
      {
        optional = true,
        variant = 'dotIndex',
      },
    }, parse.OptChain(
      'a?.b'
    ))
  end)

  spec('optchain bracketIndex', function()
    assert.has_subtable({
      {
        optional = false,
        variant = 'bracketIndex',
        value = { op = { tag = 'add' } },
      },
    }, parse.OptChain(
      'a[2 + 3]'
    ))
    assert.has_subtable({
      {
        optional = true,
        variant = 'bracketIndex',
      },
    }, parse.OptChain(
      'a?[2 + 3]'
    ))
  end)

  spec('optchain params', function()
    assert.has_subtable({
      {
        optional = false,
        variant = 'params',
        value = {
          { value = '1' },
          { value = '2' },
        },
      },
    }, parse.OptChain(
      'a(1, 2)'
    ))
    assert.has_subtable({
      {
        optional = true,
        variant = 'params',
      },
    }, parse.OptChain(
      'a?(1, 2)'
    ))
    assert.are.equal(0, #parse.OptChain('a()')[1].value)
  end)

  spec('optchain method', function()
    assert.has_subtable({
      {
        optional = false,
        variant = 'method',
        value = 'b',
      },
      { variant = 'params' },
    }, parse.OptChain(
      'a:b(1, 2)'
    ))
    assert.has_subtable({
      {
        optional = true,
        variant = 'method',
        value = 'b',
      },
      { variant = 'params' },
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

  spec('function call', function()
    assert.has_error(function()
      parse.FunctionCall('a')
    end)
    assert.has_error(function()
      parse.FunctionCall('a.b')
    end)
    assert.has_no.errors(function()
      parse.FunctionCall('hello()')
    end)
  end)

  spec('id', function()
    assert.has_error(function()
      parse.Id('a.b()')
    end)
    assert.has_no.errors(function()
      parse.Id('a.b')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('OptChain.compile', function()
  -- TODO
end)
