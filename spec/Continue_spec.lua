-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Continue.parse', function()
  spec('continue', function()
    assert.has.no_error(function()
      parse.Block([[
        while true {
          continue
        }
      ]])
    end)
  end)
end)

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
          if i % 2 == 1 {
            continue
          }
          x += i
        }
        return x
      ]])
    )
  end)
end)
