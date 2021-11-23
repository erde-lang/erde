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
          if math.ceil(i / 2) ~= math.floor(i / 2) {
            continue
          }
          x += i
        }
        return x
      ]])
    )
  end)
end)
