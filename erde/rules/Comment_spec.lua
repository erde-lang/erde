-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Comment.parse', function()
  spec('short comments', function()
    assert.are.equal(' hello world', parse.Comment('-- hello world').value)
    assert.are.equal(
      ' hello world',
      parse.Comment('-- hello world\nblah').value
    )
  end)

  spec('long comments', function()
    assert.are.equal(' hello world', parse.Comment('--[[ hello world]]').value)
    assert.are.equal('a[[b', parse.Comment('--[=[a[[b]=]').value)
    assert.are.equal(
      ' hello world\nblah ',
      parse.Comment('--[[ hello world\nblah ]]').value
    )
    assert.has_error(function()
      parse.Comment('--[[ hello')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Comment.compile', function()
  spec('short comment', function()
    assert.is_nil(compile.Comment('-- hello world'))
    assert.is_nil(compile.Comment('-- hello world\nblah'))
  end)

  spec('long comment', function()
    assert.is_nil(compile.Comment('--[[ hello world]]'))
    assert.is_nil(compile.Comment('--[[ hello world\nblah ]]'))
  end)
end)
