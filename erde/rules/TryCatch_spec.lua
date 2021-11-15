-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('TryCatch.parse', function()
  spec('ruleName', function()
    assert.are.equal('TryCatch', parse.TryCatch('try {} catch(e) {}').ruleName)
  end)

  spec('try catch', function()
    assert.has_subtable({
      try = { ruleName = 'Block' },
      catch = { ruleName = 'Block' },
    }, parse.TryCatch(
      'try {} catch() {}'
    ))
    assert.has_subtable({
      try = { ruleName = 'Block' },
      errorName = { value = 'err' },
      catch = { ruleName = 'Block' },
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
  end)
end)
