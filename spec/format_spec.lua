-- -----------------------------------------------------------------------------
-- ArrowFunction
-- -----------------------------------------------------------------------------

describe('ArrowFunction', function() end)

-- -----------------------------------------------------------------------------
-- Assignment
-- -----------------------------------------------------------------------------

describe('Assignment', function()
  spec('single line assignment', function()
    assert.formatted('local a = 1', 'local a    =     1')
    assert.formatted('local a, b = 1, 2', 'local  a ,   b = 1 ,  2')
  end)
  spec('single expr wrap', function()
    assert.formatted(
      [[
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa = 
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
      ]],
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa = bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
    )
    assert.formatted(
      [[
aaaaaaaaaaaaaaaaaaaaaaa, bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb = 
  cccccccccccccccccccccccccccccccccccccccccccc
      ]],
      'aaaaaaaaaaaaaaaaaaaaaaa, bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb = cccccccccccccccccccccccccccccccccccccccccccc'
    )
  end)
  spec('(vars, exprs) = (single, multi)', function()
    assert.formatted(
      [[
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa = (
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb,
  cccccccccccccccccccccccccccccccccccccccccccccccccc,
)
      ]],
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa = bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb, cccccccccccccccccccccccccccccccccccccccccccccccccc'
    )
  end)
  spec('(vars, exprs) = (multi, single)', function()
    assert.formatted(
      [[
(
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa,
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb,
) = cccccccccccccccccccccccccccccccccccccccccccccccccc
      ]],
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb = cccccccccccccccccccccccccccccccccccccccccccccccccc'
    )
  end)
  spec('(vars, exprs) = (multi, multi)', function()
    assert.formatted(
      [[
(
  aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa,
  bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb,
) = (
  cccccccccccccccccccccccccccccccccc,
  dddddddddddddddddddddddddddddddddddddddddddddddddd,
)
      ]],
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb = cccccccccccccccccccccccccccccccccc, dddddddddddddddddddddddddddddddddddddddddddddddddd'
    )
  end)
end)

-- -----------------------------------------------------------------------------
-- Binop
-- -----------------------------------------------------------------------------

describe('Binop', function() end)

-- -----------------------------------------------------------------------------
-- Break
-- -----------------------------------------------------------------------------

spec('Break', function()
  assert.formatted('break', '  break ')
end)

-- -----------------------------------------------------------------------------
-- Continue
-- -----------------------------------------------------------------------------

spec('Continue', function()
  assert.formatted('continue', '  continue ')
end)

-- -----------------------------------------------------------------------------
-- Declaration
-- -----------------------------------------------------------------------------

describe('Declaration', function() end)

-- -----------------------------------------------------------------------------
-- DoBlock
-- -----------------------------------------------------------------------------

describe('DoBlock', function() end)

-- -----------------------------------------------------------------------------
-- ForLoop
-- -----------------------------------------------------------------------------

describe('ForLoop', function() end)

-- -----------------------------------------------------------------------------
-- Function
-- -----------------------------------------------------------------------------

describe('Function', function() end)

-- -----------------------------------------------------------------------------
-- Goto
-- -----------------------------------------------------------------------------

describe('Goto', function() end)

-- -----------------------------------------------------------------------------
-- IfElse
-- -----------------------------------------------------------------------------

describe('IfElse', function() end)

-- -----------------------------------------------------------------------------
-- Module
-- -----------------------------------------------------------------------------

describe('Module', function() end)

-- -----------------------------------------------------------------------------
-- OptChain
-- -----------------------------------------------------------------------------

describe('OptChain', function() end)

-- -----------------------------------------------------------------------------
-- Params
-- -----------------------------------------------------------------------------

describe('Params', function() end)

-- -----------------------------------------------------------------------------
-- RepeatUntil
-- -----------------------------------------------------------------------------

describe('RepeatUntil', function() end)

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

describe('Return', function() end)

-- -----------------------------------------------------------------------------
-- Self
-- -----------------------------------------------------------------------------

describe('Self', function() end)

-- -----------------------------------------------------------------------------
-- Spread
-- -----------------------------------------------------------------------------

describe('Spread', function() end)

-- -----------------------------------------------------------------------------
-- String
-- -----------------------------------------------------------------------------

describe('String', function() end)

-- -----------------------------------------------------------------------------
-- Table
-- -----------------------------------------------------------------------------

describe('Table', function() end)

-- -----------------------------------------------------------------------------
-- TryCatch
-- -----------------------------------------------------------------------------

describe('TryCatch', function() end)

-- -----------------------------------------------------------------------------
-- Unop
-- -----------------------------------------------------------------------------

describe('Unop', function() end)

-- -----------------------------------------------------------------------------
-- WhileLoop
-- -----------------------------------------------------------------------------

describe('WhileLoop', function() end)
