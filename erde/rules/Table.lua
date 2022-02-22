-- -----------------------------------------------------------------------------
-- Table
-- -----------------------------------------------------------------------------

local Table = { ruleName = 'Table' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

local function parseExprKeyField(ctx)
  local field = {
    variant = 'exprKey',
    key = ctx:Surround('[', ']', ctx.Expr),
  }

  ctx:assert('=')
  field.value = ctx:Expr()
  return field
end

local function parseNameKeyField(ctx)
  local field = {
    variant = 'nameKey',
    key = ctx:Name(),
  }

  ctx:assert('=')
  field.value = ctx:Expr()
  return field
end

local function parseNumberKeyField(ctx)
  return { variant = 'numberKey', value = ctx:Expr() }
end

local function parseSpreadField(ctx)
  return { variant = 'spread', value = ctx:Spread() }
end

function Table.parse(ctx)
  return ctx:Surround('{', '}', function()
    return ctx:List({
      allowEmpty = true,
      allowTrailingComma = true,
      rule = function()
        return ctx:Switch({
          parseExprKeyField,
          parseNameKeyField,
          -- Parse spread before expr, otherwise we will parse the spread as
          -- varargs!
          parseSpreadField,
          parseNumberKeyField,
        })
      end,
    })
  end)
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Table.compile(ctx, node)
  local hasSpread = false
  for i, field in ipairs(node) do
    if field.variant == 'spread' then
      hasSpread = true
      break
    end
  end

  if hasSpread then
    local spreadFields = {}

    for i, field in ipairs(node) do
      if field.variant == 'spread' then
        spreadFields[i] = field.value
      else
        local spreadField = {}

        if field.variant == 'nameKey' then
          spreadField.key = '"' .. ctx:compile(field.key) .. '"'
        elseif field.variant ~= 'numberKey' then
          spreadField.key = ctx:compile(field.key)
        end

        spreadField.value = ctx:compile(field.value)
        spreadFields[i] = spreadField
      end
    end

    return ctx:Spread(spreadFields)
  else
    local fieldParts = {}

    for i, field in ipairs(node) do
      local fieldPart

      if field.variant == 'nameKey' then
        fieldPart = ctx:compile(field.key) .. ' = ' .. ctx:compile(field.value)
      elseif field.variant == 'numberKey' then
        fieldPart = ctx:compile(field.value)
      elseif field.variant == 'exprKey' then
        fieldPart = ('[%s] = %s'):format(
          ctx:compile(field.key),
          ctx:compile(field.value)
        )
      end

      fieldParts[i] = fieldPart
    end

    return '{\n' .. table.concat(fieldParts, ',\n') .. '\n}'
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Table
