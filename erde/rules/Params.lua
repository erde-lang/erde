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
    local node = { rule = 'Params' }

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
  local names = {}
  local prebody = {}

  for i, param in ipairs(node) do
    local name
    if param.value.rule == 'Name' then
      name = param.value.value
    else
      -- TODO: destructure
    end

    if param.default then
      prebody[#prebody + 1] = 'if ' .. name .. ' == nil then'
      prebody[#prebody + 1] = ctx:compile(param.default)
      prebody[#prebody + 1] = 'end'
    end

    names[#names + 1] = name
  end

  return { names = names, prebody = table.concat(prebody, '\n') }
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Params
