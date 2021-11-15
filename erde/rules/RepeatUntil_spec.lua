-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('RepeatUntil.parse', function()
  spec('ruleName', function()
    assert.are.equal(
      'RepeatUntil',
      parse.RepeatUntil('repeat {} until true').ruleName
    )
  end)

  spec('repeat until', function()
    assert.has_subtable({
      cond = { value = 'true' },
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
