-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('TryCatch.parse', function()
  spec('rule', function()
    assert.are.equal('TryCatch', parse.TryCatch('try {} catch(e) {}').rule)
  end)

  spec('try catch', function()
    assert.has_subtable({
      try = { rule = 'Block' },
      catch = { rule = 'Block' },
    }, parse.TryCatch(
      'try {} catch() {}'
    ))
    assert.has_subtable({
      try = { rule = 'Block' },
      errorName = { value = 'err' },
      catch = { rule = 'Block' },
    }, parse.TryCatch(
      'try {} catch(err) {}'
    ))
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('TryCatch.compile', function()
  spec('try catch', function()
    assert.run(
      1,
      compile.Block([[
        try {
          error('some error')
        } catch() {
          return 1
        }
        return 2
      ]])
    )
    assert.run(
      2,
      compile.Block([[
        try {
          -- no error
        } catch() {
          return 1
        }
        return 2
      ]])
    )

    if _VERSION:find('5.[34]') then
      assert.run(
        'my error',
        compile.TryCatch([[
          try {
            error(5)
          } catch(err) {
            return err
          }
        ]])
      )
    end
  end)
end)
