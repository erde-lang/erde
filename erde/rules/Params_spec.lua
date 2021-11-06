-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Params.parse', function()
  spec('rule', function()
    assert.are.equal('Params', parse.Params('()').rule)
  end)

  spec('params', function()
    assert.are.equal(0, #parse.Params('()'))
    assert.has_subtable({
      { value = { value = 'a' } },
    }, parse.Params(
      '(a)'
    ))
    assert.has_subtable({
      { value = { value = 'a' } },
      { value = { value = 'b' } },
    }, parse.Params(
      '(a, b)'
    ))
    assert.has_subtable({
      { value = { rule = 'Destructure' } },
    }, parse.Params(
      '({ :a })'
    ))
  end)

  spec('optional params', function()
    assert.has_subtable({
      {
        default = { value = '2' },
        value = { value = 'a' },
      },
    }, parse.Params(
      '(a = 2)'
    ))
  end)

  spec('params varargs', function()
    assert.has_subtable({
      { varargs = true },
    }, parse.Params('(...)'))
    assert.has_subtable({
      { value = { value = 'a' } },
      { varargs = true },
    }, parse.Params(
      '(a, ...)'
    ))
    assert.has_subtable({
      { value = { value = 'a' } },
      { varargs = true, name = 'b' },
    }, parse.Params(
      '(a, ...b)'
    ))
    assert.has_error(function()
      parse.Params('(..., a)')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Params.compile', function()
  -- TODO
end)
