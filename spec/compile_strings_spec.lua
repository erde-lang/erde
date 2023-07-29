local compile = require('erde.compile')

-- -----------------------------------------------------------------------------
-- Single Quote String
-- -----------------------------------------------------------------------------

spec('single quote string #5.1+', function()
  assert_eval('', "''")

  assert_eval('hello', "'hello'")
  assert_eval('hello\nworld', "'hello\\nworld'")
  assert_eval('\\', "'\\\\'")
end)

spec('single quote string interpolation #5.1+', function()
  assert_eval('{', "'{'")
  assert_eval('}', "'}'")

  assert_eval('{1}', "'{1}'")
  assert_eval('a{1}', "'a{1}'")
  assert_eval('{1}b', "'{1}b'")
  assert_eval('a{1}b', "'a{1}b'")
  assert_eval('a{1 + 2}b', "'a{1 + 2}b'")

  assert.has_error(function()
    compile("return '\\{'")
  end)
end)

-- -----------------------------------------------------------------------------
-- Double Quote String
-- -----------------------------------------------------------------------------

spec('double quote string #5.1+', function()
  assert_eval('', '""')

  assert_eval('hello', '"hello"')
  assert_eval('hello\nworld', '"hello\\nworld"')
  assert_eval('\\', '"\\\\"')
end)

spec('double quote string interpolation #5.1+', function()
  assert_eval('{', '"\\{"')
  assert_eval('}', '"\\}"')

  assert_eval('{1}', '"\\{1}"')
  assert_eval('{1}', '"\\{1\\}"')

  assert_eval('1', '"{1}"')
  assert_eval('a1', '"a{1}"')
  assert_eval('1b', '"{1}b"')
  assert_eval('a1b', '"a{1}b"')
  assert_eval('a3b', '"a{1 + 2}b"')
end)

-- -----------------------------------------------------------------------------
-- Block Quote String
-- -----------------------------------------------------------------------------

spec('block string #5.1+', function()
  assert_eval('', '[[]]')
  assert_eval('', '[[\n]]')

  assert_eval('hello world', '[[hello world]]')
  assert_eval(' hello\nworld', '[[ hello\nworld]]')

  assert_eval('a[[b', '[=[a[[b]=]')
end)

spec('block string interpolation #5.1+', function()
  assert_eval('{', '[[\\{]]')
  assert_eval('}', '[[\\}]]')

  assert_eval('{1}', '[[\\{1}]]')
  assert_eval('{1}', '[[\\{1\\}]]')

  assert_eval('1', '[[{1}]]')
  assert_eval('a1', '[[a{1}]]')
  assert_eval('1b', '[[{1}b]]')
  assert_eval('a1b', '[[a{1}b]]')
  assert_eval('a3b', '[[a{1 + 2}b]]')
end)

spec('block string leading newline #5.1+', function()
  assert_eval('a', '[[\na]]')
  assert_eval('1\na', '[[{1}\na]]')
end)
