local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Params
-- -----------------------------------------------------------------------------

local Params = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Params.parse(ctx)
  return ctx:Surround('(', ')', function()
    local node = {}

    repeat
      local param = {
        value = ctx:Switch({
          ctx.Name,
          ctx.Destructure,
        }),
      }

      if not param.value then
        break
      end

      if ctx:branchChar('=') then
        param.default = ctx:Expr()
      end

      node[#node + 1] = param
    until not ctx:branchChar(',')

    if ctx:branchStr('...') then
      local name = ctx:Try(ctx.Name)
      node[#node + 1] = {
        varargs = true,
        name = name and name.value or nil,
      }
    end

    return node
  end)
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Params.compile(ctx, node)
  -- TODO
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Params
