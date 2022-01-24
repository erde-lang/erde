-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('String.parse', function()
  spec('short string', function()
    assert.subtable({ '' }, parse.String('""'))
    assert.subtable({ 'hello' }, parse.String('"hello"'))
    assert.subtable({ 'hello' }, parse.String("'hello'"))
    assert.subtable({ 'hello\\nworld' }, parse.String("'hello\\nworld'"))
    assert.subtable({ '\\\\' }, parse.String("'\\\\'"))
    assert.has_error(function()
      parse.String('"hello')
    end)
    assert.has_error(function()
      parse.String('"hello\nworld"')
    end)
  end)

  spec('long string', function()
    assert.subtable({ ' hello world ' }, parse.String('[[ hello world ]]'))
    assert.subtable({ 'hello\nworld' }, parse.String('[[hello\nworld]]'))
    assert.subtable({ 'a{bc}d' }, parse.String('[[a\\{bc}d]]'))
    assert.subtable({ 'a[[b' }, parse.String('[=[a[[b]=]'))
    assert.has_error(function()
      parse.String('[[hello world')
    end)
    assert.has_error(function()
      parse.String('[[hello world {2]]')
    end)
  end)

  spec('interpolation', function()
    assert.subtable({ 'hello ', { value = '3' } }, parse.String('"hello {3}"'))
    assert.subtable({ 'hello ', { value = '3' } }, parse.String("'hello {3}'"))
    assert.subtable(
      { 'hello ', { value = '3' } },
      parse.String('[[hello {3}]]')
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('String.compile', function()
  spec('compile short string', function()
    assert.are.equal('"hello"', compile.String('"hello"'))
    assert.are.equal("'hello'", compile.String("'hello'"))
    assert.are.equal("'hello\\nworld'", compile.String("'hello\\nworld'"))
    assert.are.equal("'\\\\'", compile.String("'\\\\'"))
  end)

  spec('compile long string', function()
    assert.eval('hello world', compile.String('[[hello world]]'))
    assert.eval(' hello\nworld', compile.String('[[ hello\nworld]]'))
    assert.eval('a{bc}d', compile.String('[[a\\{bc}d]]'))
    assert.eval('a[[b', compile.String('[=[a[[b]=]'))
  end)

  spec('compile interpolation', function()
    assert.eval('hello 3', compile.String('"hello {3}"'))
    assert.eval('hello 3', compile.String("'hello {3}'"))
    assert.eval('hello 3', compile.String('[[hello {3}]]'))
  end)
end)
