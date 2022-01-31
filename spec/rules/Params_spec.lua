-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Params.parse', function()
  spec('params', function()
    assert.are.equal(0, #parse.Params('()'))
    assert.subtable({
      { value = 'a' },
    }, parse.Params('(a)'))
    assert.subtable({
      { value = 'a' },
      { value = 'b' },
    }, parse.Params(
      '(a, b)'
    ))
  end)

  spec('optional params', function()
    assert.subtable({
      {
        value = 'a',
        default = { value = '2' },
      },
    }, parse.Params(
      '(a = 2)'
    ))
  end)

  spec('params varargs', function()
    assert.subtable({
      { varargs = true },
    }, parse.Params('(...)'))
    assert.subtable({
      { value = 'a' },
      { varargs = true },
    }, parse.Params(
      '(a, ...)'
    ))
    assert.subtable({
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
    assert.subtable({
      { ruleName = 'Destructure' },
    }, parse.Params(
      '({ a })'
    ))
    assert.subtable({
      {
        ruleName = 'Destructure',
        default = { ruleName = 'Table' },
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

  spec('optional params', function()
    assert.run(
      2,
      compile.Block([[
        local function test(a = 2) {
          return a
        }
        return test()
      ]])
    )
  end)

  spec('params varargs', function()
    assert.run(
      'hello.world',
      compile.Block([[
        local function test(...) {
          return table.concat({ ... }, '.')
        }
        return test('hello', 'world')
      ]])
    )
    assert.run(
      'hello.world',
      compile.Block([[
        local function test(...args) {
          return table.concat(args, '.')
        }
        return test('hello', 'world')
      ]])
    )
  end)

  spec('destructure params', function()
    assert.run(
      3,
      compile.Block([[
        local function test({ a }, b) {
          return a + b
        }

        local x = { a = 1 }
        return test(x, 2)
      ]])
    )
  end)
end)
