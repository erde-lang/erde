-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Self.parse', function()
  spec('dotIndex', function()
    assert.subtable(
      { variant = 'dotIndex', value = 'test' },
      parse.Self('$test')
    )
  end)
  spec('numberIndex', function()
    assert.subtable(
      { variant = 'numberIndex', value = '33' },
      parse.Self('$33')
    )
  end)
  spec('self', function()
    assert.subtable({ variant = 'self' }, parse.Self('$'))
    assert.subtable({ lhs = { variant = 'self' } }, parse.Expr('$ + 1'))
    assert.subtable({ base = { variant = 'self' } }, parse.OptChain('$.y'))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Self.compile', function()
  spec('dotIndex', function()
    assert.run(
      1,
      compile.Block([[
        local x = { y = 1 }
        function x:test() {
          return $y
        }
        return x:test()
      ]])
    )
  end)
  spec('numberIndex', function()
    assert.run(
      8,
      compile.Block([[
        local x = { 9, 8, 7 }
        function x:test() {
          return $2
        }
        return x:test()
      ]])
    )
  end)
  spec('self', function()
    assert.run(
      1,
      compile.Block([[
        local x = { y = 1 }
        function x:test() {
          return $.y
        }
        return x:test()
      ]])
    )
  end)
end)
