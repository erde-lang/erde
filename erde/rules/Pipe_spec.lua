-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Pipe.parse', function()
  spec('rule', function()
    assert.are.equal('Pipe', parse.Pipe('[] >> y').rule)
    assert.are.equal('Pipe', parse.Pipe('[ 2 ] >> y').rule)
    assert.are.equal('Pipe', parse.Pipe('[ 1, 2 ] >> y').rule)
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
        return [ 1, 2, 3 ] >> sum
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
        return [ 1, 2 ] >> sum(3)
      ]])
    )
  end)
end)
