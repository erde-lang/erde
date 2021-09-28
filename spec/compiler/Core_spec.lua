local erde = require('erde')

spec('single line comment', function()
  assert.are.equal('', erde.compile('-- test'))
end)

spec('multi line comment', function()
  assert.are.equal('', erde.compile([[
  ---
  -- This is a
  -- multiline comment
  ---
  ]]))
end)

describe('ids', function()
  spec('dot index', function()
    assert.are.equal('a = 1', erde.compile('a = 1'))
    assert.are.equal('a.b.c = 1', erde.compile('a.b.c = 1'))
  end)

  spec('function calls', function()
    assert.are.equal('a()', erde.compile('a()'))
    assert.are.equal('a(x,y)', erde.compile('a(x, y)'))
    assert.are.equal('a.b.c()', erde.compile('a.b.c()'))
    assert.are.equal('a.b.c(x,y)', erde.compile('a.b.c(x, y)'))
    assert.are.equal('a.b:c()', erde.compile('a.b:c()'))
    assert.are.equal('a.b:c(x,y)', erde.compile('a.b:c(x, y)'))
  end)

  spec('method calls', function()
    assert.are.equal('a:c().d = 1', erde.compile('a:c().d = 1'))
    assert.has_error(function() erde.compile('a:c.d = 1') end)
  end)

  spec('disallow non-function-call ids as statements', function()
    assert.are.equal('', erde.compile('a.b'))
  end)
end)

spec('returns', function()
  assert.are.equal(2, erde.eval('return 2'))
  assert.is_nil(erde.eval('return'))
  assert.are.same({ 1, 2, 3 }, erde.eval([[
    local test = () -> 1, 2, 3
    return { test() }
  ]]))
  assert.are.same({ 1, 2, 3 }, erde.eval([[
    local test = () -> {
      return 1, 2, 3
    }
    return { test() }
  ]]))
  assert.are.same({ 1, 2, 3 }, erde.eval([[
    local test = () -> {
      return (
        1,
        2,
        3,
      )
    }
    return { test() }
  ]]))
end)
