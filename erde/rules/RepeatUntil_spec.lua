-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('RepeatUntil.parse', function()
  spec('rule', function()
    assert.are.equal(
      'RepeatUntil',
      parse.RepeatUntil('repeat {} until (true)').rule
    )
  end)

  spec('repeat until', function()
    assert.has_subtable({
      cond = { value = 'true' },
    }, parse.RepeatUntil(
      'repeat {} until (true)'
    ))
    assert.has_error(function()
      parse.RepeatUntil('repeat {} until true')
    end)
    assert.has_error(function()
      parse.RepeatUntil('repeat {} until ()')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('RepeatUntil.compile', function()
  -- TODO
end)
