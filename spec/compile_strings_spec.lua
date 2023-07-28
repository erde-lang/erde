-- -----------------------------------------------------------------------------
-- Single Quote String
-- -----------------------------------------------------------------------------

spec('single quote string #5.1+', function()
  assert_eval('', "''")
  assert_eval('hello', "'hello'")
  assert_eval('hello\nworld', "'hello\\nworld'")
  assert_eval('\\', "'\\\\'")

  assert_eval('hello {1 + 2}', "'hello {1 + 2}'")
end)

-- -----------------------------------------------------------------------------
-- Double Quote String
-- -----------------------------------------------------------------------------

spec('double quote string #5.1+', function()
  assert_eval('', '""')
  assert_eval('hello', '"hello"')
  assert_eval('hello\nworld', '"hello\\nworld"')
  assert_eval('\\', '"\\\\"')

  assert_eval('hello 3', '"hello {1 + 2}"')
end)

-- -----------------------------------------------------------------------------
-- Block Quote String
-- -----------------------------------------------------------------------------

spec('block string #5.1+', function()
  assert_eval('hello world', '[[hello world]]')
  assert_eval(' hello\nworld', '[[ hello\nworld]]')
  assert_eval('a{bc}d', '[[a\\{bc}d]]')
  assert_eval('a[[b', '[=[a[[b]=]')
  assert_eval('a', '[[\na]]')
  assert_eval('3\na', '[[{1 + 2}\na]]')

  assert_eval('hello 3', '[[hello {1 + 2}]]')
end)
