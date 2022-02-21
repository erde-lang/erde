-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Assignment.parse', function()
  spec('name assignment', function()
    assert.subtable({
      id = { value = 'a' },
      expr = { value = '3' },
    }, parse.Assignment(
      'a = 3'
    ))
  end)

  spec('optchain assignment', function()
    assert.subtable({
      id = { ruleName = 'OptChain' },
      expr = { value = '3' },
    }, parse.Assignment(
      'a.b = 3'
    ))
    assert.subtable({
      id = { ruleName = 'OptChain' },
      expr = { value = '3' },
    }, parse.Assignment(
      'a?.b = 3'
    ))
  end)

  spec('binop assignments', function()
    assert.subtable({
      op = { token = '+' },
      id = { value = 'a' },
      expr = { value = '1' },
    }, parse.Assignment(
      'a += 1'
    ))
    assert.subtable({
      op = { token = '+' },
    }, parse.Assignment(
      'a?.b += 1'
    ))

    assert.are.equal('??', parse.Assignment('a ??= 1').op.token)
    assert.are.equal('|', parse.Assignment('a |= 1').op.token)
    assert.are.equal('&', parse.Assignment('a &= 1').op.token)
    assert.are.equal('.|', parse.Assignment('a .|= 1').op.token)
    assert.are.equal('.~', parse.Assignment('a .~= 1').op.token)
    assert.are.equal('.&', parse.Assignment('a .&= 1').op.token)
    assert.are.equal('.<<', parse.Assignment('a .<<= 1').op.token)
    assert.are.equal('.>>', parse.Assignment('a .>>= 1').op.token)
    assert.are.equal('..', parse.Assignment('a ..= 1').op.token)
    assert.are.equal('+', parse.Assignment('a += 1').op.token)
    assert.are.equal('-', parse.Assignment('a -= 1').op.token)
    assert.are.equal('*', parse.Assignment('a *= 1').op.token)
    assert.are.equal('/', parse.Assignment('a /= 1').op.token)
    assert.are.equal('//', parse.Assignment('a //= 1').op.token)
    assert.are.equal('%', parse.Assignment('a %= 1').op.token)
    assert.are.equal('^', parse.Assignment('a ^= 1').op.token)
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
  spec('name assignment', function()
    assert.run(
      1,
      compile.Block([[
        local a
        a = 1
        return a
      ]])
    )
  end)

  spec('optchain assignment', function()
    assert.run(
      1,
      compile.Block([[
        local a = {}
        a.b = 1
        return a.b
      ]])
    )
    assert.run(
      nil,
      compile.Block([[
        local a
        a?.b = 1
        return a?.b
      ]])
    )
  end)

  spec('binop assignment', function()
    assert.run(
      3,
      compile.Block([[
        local a = 1
        a += 2
        return a
      ]])
    )
    assert.run(
      4,
      compile.Block([[
        local a = 5
        a .&= 6
        return a
      ]])
    )
  end)
end)
