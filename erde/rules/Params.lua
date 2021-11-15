-- -----------------------------------------------------------------------------
-- Params
-- -----------------------------------------------------------------------------

local Params = { ruleName = 'Params' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Params.parse(ctx)
  return ctx:Parens({
    demand = true,
    rule = function()
      local node = ctx:List({
        allowEmpty = true,
        allowTrailingComma = true,
        rule = function()
          local param = ctx:Switch({
            ctx.Name,
            ctx.Destructure,
          })

          if param and ctx:branchChar('=') then
            param.default = ctx:Expr()
          end

          return param
        end,
      })

      if ctx:branchStr('...') then
        node[#node + 1] = {
          varargs = true,
          name = ctx:Try(ctx.Name),
        }
      end

      return node
    end,
  })
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Params.compile(ctx, node)
  local names = {}
  local prebody = {}

  for i, param in ipairs(node) do
    local name, destructure
    if param.ruleName == 'Name' then
      name = ctx:compile(param)
    else
      destructure = ctx:compile(param)
      name = destructure.baseName
    end

    if param.default then
      prebody[#prebody + 1] = 'if ' .. name .. ' == nil then'
      prebody[#prebody + 1] = ctx:compile(param.default)
      prebody[#prebody + 1] = 'end'
    end

    if destructure then
      prebody[#prebody + 1] = destructure.compiled
    end

    names[#names + 1] = name
  end

  return { names = names, prebody = table.concat(prebody, '\n') }
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Params
