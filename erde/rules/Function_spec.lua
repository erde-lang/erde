-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Function.parse', function()
  spec('rule', function()
    assert.are.equal('Function', parse.Function('function a() {}').rule)
  end)

  spec('local function', function()
    assert.has_subtable({
      variant = 'local',
      names = { 'a' },
    }, parse.Function(
      'local function a() {}'
    ))
    assert.has_error(function()
      parse.ArrowFunction('local function() {}')
    end)
  end)

  spec('global function', function()
    assert.has_subtable({
      variant = 'global',
      names = { 'a' },
    }, parse.Function(
      'function a() {}'
    ))
    assert.has_error(function()
      parse.ArrowFunction('function() {}')
    end)
    assert.has_error(function()
      parse.ArrowFunction('global function a() {}')
    end)
  end)

  spec('method function', function()
    assert.has_subtable({
      isMethod = true,
      names = { 'a', 'b' },
    }, parse.Function(
      'function a:b() {}'
    ))
    assert.has_error(function()
      parse.FunctionCall('function a:b.c() {}')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Function.compile', function()
  -- TODO
end)
