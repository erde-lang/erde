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
      { value = 'a' },
    }, parse.Params('(a)'))
    assert.has_subtable({
      { value = 'a' },
      { value = 'b' },
    }, parse.Params(
      '(a, b)'
    ))
  end)

  spec('optional params', function()
    assert.has_subtable({
      {
        value = 'a',
        default = { value = '2' },
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
      { value = 'a' },
      { varargs = true },
    }, parse.Params(
      '(a, ...)'
    ))
    assert.has_subtable({
      { value = 'a' },
      {
        varargs = true,
        name = { value = 'b' },
      },
    }, parse.Params(
      '(a, ...b)'
    ))
    assert.has_error(function()
      parse.Params('(..., a)')
    end)
  end)

  spec('destructure params', function()
    assert.has_subtable({
      { rule = 'Destructure' },
    }, parse.Params(
      '({ :a })'
    ))
    assert.has_subtable({
      {
        rule = 'Destructure',
        default = { rule = 'Table' },
      },
    }, parse.Params(
      '({ a } = { 2 })'
    ))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Params.compile', function()
  spec('params', function()
    assert.run(
      3,
      compile.Block([[
        local function test(a, b) {
          return a + b
        }
        return test(1, 2)
      ]])
    )
  end)

  spec('destructure params', function()
    assert.run(
      3,
      compile.Block([[
        local function test({ :a }, b) {
          return a + b
        }

        local x = { a: 1 }
        return test(x, 2)
      ]])
    )
  end)
end)
