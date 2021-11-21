-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Pipe.parse', function()
  -- TODO
  spec('ruleName', function()
    assert.are.equal('Pipe', parse.Expr('(1, 2) >> y').ruleName)
    assert.are.equal('Pipe', parse.Expr('2 >> y').ruleName)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Pipe.compile', function()
  spec('expr pipes', function()
    assert.run(
      6,
      compile.Block([[
        function sum(a, b, c) {
          return a + b + c
        }
        return (1, 2, 3) >> sum()
      ]])
    )
  end)
  spec('param pipes', function()
    assert.run(
      6,
      compile.Block([[
        function sum(a, b, c) {
          return a + b + c
        }
        return (1, 2) >> sum(3)
      ]])
    )
  end)
end)
