-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Assignment.parse', function()
  spec('rule', function()
    assert.are.equal('Assignment', parse.Assignment('a = 1').rule)
  end)

  spec('single assignment', function()
    assert.has_subtable({
      idList = { { value = 'a' } },
      exprList = { { value = '3' } },
    }, parse.Assignment(
      'a = 3'
    ))
    assert.has_subtable({
      idList = { { rule = 'OptChain' } },
      exprList = { { value = '3' } },
    }, parse.Assignment(
      'a.b = 3'
    ))
  end)

  spec('multiple assignment', function()
    assert.has_subtable({
      idList = {
        { value = 'a' },
        { value = 'b' },
      },
      exprList = {
        { value = '1' },
        { value = '2' },
      },
    }, parse.Assignment(
      'a, b = 1, 2'
    ))
    assert.has_subtable({
      idList = {
        { value = 'a' },
        { rule = 'OptChain' },
      },
      exprList = {
        { value = '1' },
        { value = '2' },
      },
    }, parse.Assignment(
      'a, b.c = 1, 2'
    ))
    assert.has_error(function()
      parse.Assignment('a, b += 1, 2')
    end)
    assert.has_error(function()
      unit.Var('a, = 1')
    end)
    assert.has_error(function()
      unit.Var('a, b = 1,')
    end)
  end)

  spec('binop assignment', function()
    assert.are.equal('nc', parse.Assignment('a ??= 1').op.tag)
    assert.are.equal('or', parse.Assignment('a |= 1').op.tag)
    assert.are.equal('and', parse.Assignment('a &= 1').op.tag)
    assert.are.equal('bor', parse.Assignment('a .|= 1').op.tag)
    assert.are.equal('bxor', parse.Assignment('a .~= 1').op.tag)
    assert.are.equal('band', parse.Assignment('a .&= 1').op.tag)
    assert.are.equal('lshift', parse.Assignment('a .<<= 1').op.tag)
    assert.are.equal('rshift', parse.Assignment('a .>>= 1').op.tag)
    assert.are.equal('concat', parse.Assignment('a ..= 1').op.tag)
    assert.are.equal('add', parse.Assignment('a += 1').op.tag)
    assert.are.equal('sub', parse.Assignment('a -= 1').op.tag)
    assert.are.equal('mult', parse.Assignment('a *= 1').op.tag)
    assert.are.equal('div', parse.Assignment('a /= 1').op.tag)
    assert.are.equal('intdiv', parse.Assignment('a //= 1').op.tag)
    assert.are.equal('mod', parse.Assignment('a %= 1').op.tag)
    assert.are.equal('exp', parse.Assignment('a ^= 1').op.tag)
    assert.has_subtable({
      idList = { { value = 'a' } },
      op = { tag = 'add' },
      exprList = { { value = '3' } },
    }, parse.Assignment(
      'a += 3'
    ))
  end)

  spec('binop blacklist', function()
    assert.has_error(function()
      parse.Assignment('a >>= 1')
    end)
    assert.has_error(function()
      parse.Assignment('a ?= 1')
    end)
    assert.has_error(function()
      parse.Assignment('a === 1')
    end)
    assert.has_error(function()
      parse.Assignment('a ~== 1')
    end)
    assert.has_error(function()
      parse.Assignment('a <== 1')
    end)
    assert.has_error(function()
      parse.Assignment('a >== 1')
    end)
    assert.has_error(function()
      parse.Assignment('a <= 1')
    end)
    assert.has_error(function()
      parse.Assignment('a >= 1')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Assignment.compile', function()
  -- TODO
end)
