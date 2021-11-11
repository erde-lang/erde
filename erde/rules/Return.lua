local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

local Return = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Return.parse(ctx)
  if not ctx:branchWord('return') then
    ctx:throwExpected('return')
  end

  local node = ctx:Switch({
    function()
      return { ctx:Pipe() }
    end,
    function()
      return ctx:Parens({
        allowRecursion = true,
        rule = function()
          return ctx:List({
            allowEmpty = true,
            allowTrailingComma = true,
            rule = ctx.Expr,
          })
        end,
      })
    end,
  })

  node.rule = 'Return'
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
