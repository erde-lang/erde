-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('RepeatUntil.parse', function()
  spec('repeat until', function()
    assert.subtable({
      condition = 'true',
    }, parse.RepeatUntil(
      'repeat {} until true'
    ))
    assert.has_error(function()
      parse.RepeatUntil('repeat {} until ()')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('RepeatUntil.compile', function()
  spec('repeat until', function()
    assert.run(
      12,
      compile.Block([[
        local x = 0
        repeat {
          x += 2
        } until x > 10
        return x
      ]])
    )
  end)
end)
