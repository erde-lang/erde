-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Goto.parse', function()
  spec('definition', function()
    assert.subtable({
      variant = 'definition',
      name = 'mylabel',
    }, parse.Goto('::mylabel::'))
  end)
  spec('jump', function()
    assert.subtable({
      variant = 'jump',
      name = 'mylabel',
    }, parse.Goto('goto mylabel'))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Goto.compile', function()
  spec('goto', function()
    assert.run(
      1,
      compile.Block([[
        local x
        x = 1
        goto test
        x = 2
        ::test::
        return x
      ]])
    )
  end)
end)
