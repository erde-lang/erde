-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('ArrowFunction.parse', function()
  spec('skinny arrow function', function()
    assert.subtable(
      { hasFatArrow = false },
      parse.ArrowFunction('() -> { return 1 }')
    )
  end)

  spec('fat arrow function', function()
    assert.subtable(
      { hasFatArrow = true },
      parse.ArrowFunction('() => { return 1 }')
    )
  end)

  spec('arrow function implicit params', function()
    assert.subtable(
      { params = { { value = 'a' } } },
      parse.ArrowFunction('a -> {}')
    )
    assert.subtable(
      { params = { { value = { { name = 'a', variant = 'keyDestruct' } } } } },
      parse.ArrowFunction('{ a } -> {}')
    )
    assert.subtable({
      params = {
        { value = { { name = 'a', variant = 'numberDestruct' } } },
      },
    }, parse.ArrowFunction(
      '[ a ] -> {}'
    ))
    assert.error(function()
      parse.ArrowFunction('a = 1 -> {}')
    end)
    assert.error(function()
      parse.ArrowFunction('...a -> {}')
    end)
    assert.error(function()
      parse.ArrowFunction('a.b -> {}')
    end)
  end)

  spec('arrow function implicit returns', function()
    assert.subtable({
      hasImplicitReturns = true,
      returns = { { value = '1' } },
    }, parse.ArrowFunction(
      '() -> 1'
    ))
    assert.subtable({
      hasImplicitReturns = true,
      returns = {
        { value = '1' },
        { value = '2' },
      },
    }, parse.ArrowFunction(
      '() -> (1, 2)'
    ))
    assert.error(function()
      parse.ArrowFunction('() -> ()')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('ArrowFunction.compile', function()
  spec('skinny arrow function', function()
    assert.eval('function', compile.OptChain('type(() -> {})'))
    assert.run(
      3,
      compile.Block([[
        local a = (x, y) -> { return x + y }
        return a(1, 2)
      ]])
    )
  end)

  spec('fat arrow function', function()
    assert.eval('function', compile.OptChain('type(() => {})'))
    assert.run(
      2,
      compile.Block([[
        local a = { b = 1 }
        a.c = () => { return self.b + 1 }
        return a:c()
      ]])
    )
  end)

  spec('arrow function iife', function()
    assert.eval(1, compile.OptChain('(() -> { return 1 })()'))
  end)

  spec('arrow function implicit returns', function()
    assert.run(
      1,
      compile.Block([[
        local a = () -> 1
        return a()
      ]])
    )
    assert.run(
      3,
      compile.Block([[
        local a = () -> (1, 2)
        local b, c = a()
        return b + c
      ]])
    )
  end)

  spec('arrow function implicit params', function()
    assert.run(
      2,
      compile.Block([[
        local a = x -> { return x + 1 }
        return a(1)
      ]])
    )
    assert.run(
      2,
      compile.Block([[
        local a = [ x ] -> { return x + 1 }
        return a({ 1 })
      ]])
    )
    assert.run(
      2,
      compile.Block([[
        local a = { x } -> { return x + 1 }
        return a({ x = 1 })
      ]])
    )
    assert.run(
      2,
      compile.Block([[
        local a = { b = 1 }
        a.c = x => { return self.b + x }
        return a:c(1)
      ]])
    )
  end)
end)
