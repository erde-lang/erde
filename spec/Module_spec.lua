-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Module.parse', function()
  spec('hoisted declarations', function()
    assert.subtable(
      { hoistedNames = { 'x', 'y' } },
      parse.Module('local x = 1 local y')
    )
    assert.subtable(
      { hoistedNames = { 'x', 'y', 'z' } },
      parse.Module('local x, y = 1 local z')
    )
    assert.are.equal(0, #parse.Module('if true { local x = 1 }').hoistedNames)
    assert.are.equal(0, #parse.Module('global x = 1').hoistedNames)
  end)
  spec('hoisted functions', function()
    assert.subtable(
      { hoistedNames = { 'test' } },
      parse.Module('local function test() {}')
    )
    assert.are.equal(0, #parse.Module('function test() {}').hoistedNames)
    assert.are.equal(0, #parse.Module('function a.b() {}').hoistedNames)
    assert.are.equal(
      0,
      #parse.Module('if true { local function test() {} }').hoistedNames
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Module.compile', function()
  spec('hoisted declarations', function()
    assert.run(
      4,
      compile.Module([[
        local function test() {
          return x
        }

        local x = 4
        return test()
      ]])
    )
  end)
  spec('hoisted functions', function()
    assert.run(
      5,
      compile.Module([[
        local function test1() {
          return test2()
        }

        local function test2() {
          return 5
        }

        return test1()
      ]])
    )
  end)
end)
