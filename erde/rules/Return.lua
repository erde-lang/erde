-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

local Return = { ruleName = 'Return' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Return.parse(ctx)
  if not ctx:branchWord('return') then
    error()
  end

  local node = ctx:Parens({
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

  return node
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
