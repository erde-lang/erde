-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('String.parse', function()
  spec('ruleName', function()
    assert.are.equal('String', parse.String('""').ruleName)
  end)

  spec('short string', function()
    assert.are.equal('"hello"', parse.String('"hello"').value)
    assert.are.equal("'hello'", parse.String("'hello'").value)
    assert.are.equal("'hello\\nworld'", parse.String("'hello\\nworld'").value)
    assert.are.equal("'\\\\'", parse.String("'\\\\'").value)
    assert.has_error(function()
      parse.String('"hello')
    end)
    assert.has_error(function()
      parse.String('"hello\nworld"')
    end)
  end)

  spec('long string', function()
    assert.has_subtable({ 'hello world' }, parse.String('`hello world`'))
    assert.has_subtable({ 'hello\nworld' }, parse.String('`hello\nworld`'))
    assert.has_subtable({ 'a{bc}d' }, parse.String('`a\\{bc}d`'))
    assert.has_subtable({ 'a`b' }, parse.String('`a\\`b`'))
    assert.has_subtable(
      { 'hello ', { value = '3' } },
      parse.String('`hello {3}`')
    )
    assert.has_error(function()
      parse.String('`hello world')
    end)
    assert.has_error(function()
      parse.String('`hello world {2`')
    end)
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
    assert.eval('hello world', compile.String('`hello world`'))
    assert.eval('hello\nworld', compile.String('`hello\nworld`'))
    assert.eval('a{bc}d', compile.String('`a\\{bc}d`'))
    assert.eval('a`b', compile.String('`a\\`b`'))
    assert.eval('hello 3', compile.String('`hello {3}`'))
  end)
end)
