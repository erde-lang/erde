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
      local node, hasTrailingComma = ctx:List({
        allowEmpty = true,
        allowTrailingComma = true,
        rule = function()
          local param
          if ctx.token == '{' or ctx.token == '(' then
            param = ctx:Destructure()
          else
            param = ctx:Name()
          end

          if param and ctx:branch('=') then
            param.default = ctx:Expr()
          end

          return param
        end,
      })

      if (#node == 0 or hasTrailingComma) and ctx:branch('...') then
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

    if param.varargs then
      name = '...'
      if param.name then
        prebody[#prebody + 1] = 'local '
          .. ctx:compile(param.name)
          .. ' = { ... }'
      end
    elseif param.ruleName == 'Name' then
      name = ctx:compile(param)
    else
      destructure = ctx:compile(param)
      name = destructure.baseName
    end

    if param.default then
      prebody[#prebody + 1] = 'if ' .. name .. ' == nil then'
      prebody[#prebody + 1] = name .. ' = ' .. ctx:compile(param.default)
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
