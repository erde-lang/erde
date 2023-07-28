local lib = require('erde.lib')

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------

local function assert_rewrite(source, expected)
  local ok, result = xpcall(function() lib.run(source) end, lib.rewrite)
  assert.are.equal(false, ok)
  assert.are.equal(expected, result)
end

-- -----------------------------------------------------------------------------
-- Tests
-- -----------------------------------------------------------------------------

describe('error rewriting', function()
  spec('#jit #5.1 #5.2 #5.3', function()
    assert_rewrite(
      [[print('a' + 1)]],
      [[[string "print..."]:1: attempt to perform arithmetic on a string value]]
    )

    assert_rewrite(
      [[

        print('a' + 1)
      ]],
      [[[string "print..."]:2: attempt to perform arithmetic on a string value]]
    )

    assert_rewrite(
      [[print(
        'a' + 1)]],
      [[[string "print..."]:2: attempt to perform arithmetic on a string value]]
    )

    assert_rewrite(
      [[



      error('myerror')
      ]],
      [[[string "error..."]:4: myerror]]
    )
  end)

  spec('#5.4', function()
    assert_rewrite(
      [[print('a' + 1)]],
      [[[string "print..."]:1: attempt to add a 'string' with a 'number']]
    )

    assert_rewrite(
      [[

        print('a' + 1)
      ]],
      [[[string "print..."]:2: attempt to add a 'string' with a 'number']]
    )

    assert_rewrite(
      [[print(
        'a' + 1)]],
      [[[string "print..."]:2: attempt to add a 'string' with a 'number']]
    )

    assert_rewrite(
      [[



      error('myerror')
      ]],
      [[[string "error..."]:4: myerror]]
    )
  end)
end)
