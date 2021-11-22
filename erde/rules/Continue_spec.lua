-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Continue.compile', function()
  spec('continue', function()
    assert.run(
      30,
      compile.Block([[
        local x = 0
        for i = 1, 10 {
          if math.ceil(x / 2) == 1 {
            continue
          }
          x += i
        }
        return x
      ]])
    )
  end)
end)
