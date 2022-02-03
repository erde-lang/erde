-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

local Return = { ruleName = 'Return' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Return.parse(ctx)
  ctx:assert('return')
  return ctx:Parens({
    allowRecursion = true,
    prioritizeRule = true,
    rule = function()
      return ctx:List({
        allowEmpty = true,
        allowTrailingComma = true,
        rule = ctx.Expr,
      })
    end,
  })
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Return.compile(ctx, node)
  local returnValues = {}

  for i, returnValue in ipairs(node) do
    returnValues[#returnValues + 1] = ctx:compile(returnValue)
  end

  return 'return ' .. table.concat(returnValues, ',')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Return
