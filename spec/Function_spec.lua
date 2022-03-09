local utils = require('erde.utils')

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

describe('Function.parse', function()
  spec('local function', function()
    assert.subtable({
      variant = 'local',
      names = { 'a' },
    }, parse.Function('local function a() {}'))
  end)

  spec('global function', function()
    assert.subtable({
      variant = 'global',
      names = { 'a' },
    }, parse.Function('function a() {}'))
  end)

  spec('module function', function()
    assert.subtable({
      {
        variant = 'module',
        names = { 'a' },
      },
    }, parse.Block('module function a() {}'))
    assert.has_error(function()
      parse.Block('module function a.b() {}')
    end)
  end)

  spec('main function', function()
    assert.subtable({
      {
        variant = 'main',
        names = { 'a' },
      },
    }, parse.Block('main function a() {}'))
    assert.has_error(function()
      parse.Block('main function a.b() {}')
    end)
  end)

  spec('method function', function()
    assert.subtable({
      isMethod = true,
      names = { 'a', 'b' },
    }, parse.Function('function a:b() {}'))
    assert.has_error(function()
      parse.Function('function a:b.c() {}')
    end)
  end)
end)

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

describe('Function.compile', function()
  spec('local function', function()
    assert.run(
      2,
      compile.Block([[
        local function test() {
          return 2
        }

        do {
          local function test() {
            return 1
          }
        }

        return test()
      ]])
    )
  end)

  spec('global function', function()
    assert.run(
      1,
      compile.Block([[
        function test() {
          return 2
        }

        do {
          function test() {
            return 1
          }
        }

        return test()
      ]])
    )
  end)

  spec('module function', function()
    local testModule = utils.run(compile.Block([[
      module function test() {
        return 1
      }
    ]]))
    assert.are.equal(1, testModule.test())
  end)

  spec('main function', function()
    local testModule = utils.run(compile.Block([[
      main function test() {
        return 1
      }
    ]]))
    assert.are.equal(1, testModule())
  end)

  spec('method function', function()
    assert.run(
      1,
      compile.Block([[
        local a = { x = 1 }

        function a:test() {
          return self.x
        }

        return a:test()
      ]])
    )
  end)
end)
