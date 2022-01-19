-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Break.parse', function()
  spec('break', function()
    parse.Block([[
      local x = 0
      break
    ]])
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
