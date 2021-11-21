-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Continue.compile', function()
  spec('continue', function()
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
