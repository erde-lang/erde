-- -----------------------------------------------------------------------------
-- Table
-- -----------------------------------------------------------------------------

local Table = { ruleName = 'Table' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

local function parseInlineKeyField(ctx)
  if not ctx:branchChar(':') then
    ctx:throwExpected(':')
  end

  return {
    variant = 'inlineKey',
    key = ctx:Name().value,
  }
end

local function parseExprKeyField(ctx)
  local field = {
    variant = 'exprKey',
    key = ctx:Surround('[', ']', ctx.Expr),
  }

  if not ctx:branchChar(':') then
    ctx:throwExpected(':')
  end

  field.value = ctx:Expr()
  return field
end

local function parseNameKeyField(ctx)
  local field = {
    variant = 'nameKey',
    key = ctx:Name().value,
  }

  if not ctx:branchChar(':') then
    ctx:throwExpected(':')
  end

  field.value = ctx:Expr()
  return field
end

local function parseStringKeyField(ctx)
  local field = {
    variant = 'stringKey',
    key = ctx:String(),
  }

  if not ctx:branchChar(':') then
    ctx:throwExpected(':')
  end

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
          parseInlineKeyField,
          parseExprKeyField,
          parseNameKeyField,
          parseStringKeyField,
          -- numberKey must be after stringKey! Otherwise we will parse the
          -- key of stringKey as the value of numberKey
          parseNumberKeyField,
          parseSpreadField,
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
      spreadFields[i] = {
        key = (field.variant == 'inlineKey' or field.variant == 'nameKey')
            and '"' .. field.key .. '"'
          or ctx:compile(field.key),
        value = field.variant == 'inlineKey' and field.key or ctx:compile(
          field.value
        ),
      }
    end

    return ctx:Spread(spreadFields)
  else
    local fieldParts = {}

    for i, field in ipairs(node) do
      local fieldPart

      if field.variant == 'inlineKey' then
        fieldPart = field.key .. ' = ' .. field.key
      elseif field.variant == 'nameKey' then
        fieldPart = field.key .. ' = ' .. ctx:compile(field.value)
      elseif field.variant == 'numberKey' then
        fieldPart = ctx:compile(field.value)
      elseif field.variant == 'exprKey' or field.variant == 'stringKey' then
        fieldPart = ctx.format(
          -- Note: Space around brackets are necessary to avoid long string
          -- expressions: [ [=[some string]=] ]
          '[ %1 ] = %2',
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
