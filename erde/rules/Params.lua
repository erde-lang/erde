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
          local param = { value = ctx:Var() }

          if param and ctx:branch('=') then
            param.default = ctx:Expr()
          end

          return param
        end,
      })

      if (#node == 0 or hasTrailingComma) and ctx:branch('...') then
        table.insert(node, {
          varargs = true,
          value = ctx:Try(ctx.Name),
        })
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
      if param.value then
        table.insert(prebody, 'local ' .. param.value .. ' = { ... }')
      end
    elseif type(param.value) == 'string' then
      name = param.value
    else
      destructure = ctx:compile(param.value)
      name = destructure.baseName
    end

    if param.default then
      table.insert(prebody, 'if ' .. name .. ' == nil then')
      table.insert(prebody, name .. ' = ' .. ctx:compile(param.default))
      table.insert(prebody, 'end')
    end

    if destructure then
      table.insert(prebody, destructure.compiled)
    end

    table.insert(names, name)
  end

  return { names = names, prebody = table.concat(prebody, '\n') }
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Params
