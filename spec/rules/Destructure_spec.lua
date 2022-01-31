-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Destructure.parse', function()
  spec('destructure keyDestruct', function()
    assert.subtable({
      { name = 'a', variant = 'keyDestruct' },
    }, parse.Destructure(
      '{ a }'
    ))
    assert.has_error(function()
      parse.Destructure('{}')
    end)
  end)

  spec('destructure numberDestruct', function()
    assert.subtable({
      { name = 'a', variant = 'numberDestruct' },
      { name = 'b', variant = 'numberDestruct' },
    }, parse.Destructure(
      '[ a, b ]'
    ))
    assert.subtable({
      { name = 'a', variant = 'numberDestruct' },
      { name = 'b', variant = 'numberDestruct' },
    }, parse.Destructure(
      '{[ a, b ]}'
    ))
    assert.subtable({
      { name = 'a', variant = 'numberDestruct' },
      { name = 'b', variant = 'numberDestruct' },
    }, parse.Destructure(
      '{[a], [b]}'
    ))
  end)

  spec('destructure mixed', function()
    assert.subtable({
      { name = 'a', variant = 'keyDestruct' },
      { name = 'b', variant = 'numberDestruct' },
      { name = 'c', variant = 'numberDestruct' },
    }, parse.Destructure(
      '{ a, [b, c] } '
    ))
  end)
end)
