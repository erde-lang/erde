-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Break.parse', function()
  spec('ruleName', function()
    assert.are.equal('Break', parse.Break('break').ruleName)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Break.compile', function()
  spec('break', function()
    assert.run(
      6,
      compile.Block([[
        local x = 0
        while x < 10 {
          x += 2
          if x > 4 {
            break
          }
        }
        return x
      ]])
    )
  end)
end)
