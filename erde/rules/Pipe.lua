local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Pipe
-- -----------------------------------------------------------------------------

local Pipe = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Pipe.parse(ctx)
  local node = {
    rule = 'Pipe',
    initValues = ctx.bufValue ~= '(' and { ctx:Expr() } or ctx:Parens({
      demand = true,
      allowRecursion = true,
      rule = function()
        return ctx:List({
          allowTrailingComma = true,
          rule = ctx.Expr,
        })
      end,
    }),
  }

  while true do
    local backup = ctx:backup()
    local pipe = { optional = ctx:branchChar('?') }

    if not ctx:branchStr('>>') then
      ctx:restore(backup) -- revert consumption from ctx:branchChar('?')
      break
    end

    pipe.receiver = ctx:Expr()
    node[#node + 1] = pipe
  end

  if #node == 0 then
    ctx:throwExpected('>>')
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Pipe.compile(ctx, node)
  return node.value
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Pipe
