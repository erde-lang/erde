-- -----------------------------------------------------------------------------
-- Key Fields
-- -----------------------------------------------------------------------------

--
-- inlineKeyField
--

local inlineKeyField = {}

function inlineKeyField.parse(ctx)
  if not ctx:branchChar(':') then
    ctx:throwExpected(':')
  end

  return {
    variant = 'inlineKey',
    key = ctx:Name().value,
  }
end

function inlineKeyField.compile(ctx, field)
  return field.key .. ' = ' .. field.key
end

--
-- exprKeyField
--

local exprKeyField = {}

function exprKeyField.parse(ctx)
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

function exprKeyField.compile(ctx, field)
  return ctx.format(
    -- Note: Space around brackets are necessary to avoid long string
    -- expressions: [ [=[some string]=] ]
    '[ %1 ] = %2',
    ctx:compile(field.key),
    ctx:compile(field.value)
  )
end

--
-- nameKeyField
--

local nameKeyField = {}

function nameKeyField.parse(ctx)
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

function nameKeyField.compile(ctx, field)
  return field.key .. ' = ' .. ctx:compile(field.value)
end

--
-- stringKeyField
--

local stringKeyField = {}

function stringKeyField.parse(ctx)
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

function stringKeyField.compile(ctx, field)
  return ctx.format(
    -- Note: Space around brackets are necessary to avoid long string
    -- expressions: [ [=[some string]=] ]
    '[ %1 ] = %2',
    ctx:compile(field.key),
    ctx:compile(field.value)
  )
end

--
-- numberKeyField
--

local numberKeyField = {}

function numberKeyField.parse(ctx)
  return { variant = 'numberKey', value = ctx:Expr() }
end

function numberKeyField.compile(ctx, field)
  return ctx:compile(field.value)
end

--
-- spreadField
--

local spreadField = {}

function spreadField.parse(ctx)
  return { variant = 'spread', value = ctx:Spread() }
end

function spreadField.compile(ctx, field)
  return ctx:compile(field.value)
end

-- -----------------------------------------------------------------------------
-- Table
-- -----------------------------------------------------------------------------

local Table = { ruleName = 'Table' }

--
-- Parse
--

function Table.parse(ctx)
  return ctx:Surround('{', '}', function()
    return ctx:List({
      allowEmpty = true,
      allowTrailingComma = true,
      rule = function()
        return ctx:Switch({
          inlineKeyField.parse,
          exprKeyField.parse,
          nameKeyField.parse,
          stringKeyField.parse,
          -- numberKey must be after stringKey! Otherwise we will parse the
          -- key of stringKey as the value of numberKey
          numberKeyField.parse,
        })
      end,
    })
  end)
end

--
-- Compile
--

function Table.compile(ctx, node)
  local compileParts = { '{' }

  for i, field in ipairs(node) do
    local fieldCompiler

    if field.variant == 'inlineKey' then
      fieldCompiler = inlineKeyField.compile
    elseif field.variant == 'exprKey' then
      fieldCompiler = exprKeyField.compile
    elseif field.variant == 'nameKey' then
      fieldCompiler = nameKeyField.compile
    elseif field.variant == 'stringKey' then
      fieldCompiler = stringKeyField.compile
    elseif field.variant == 'numberKey' then
      fieldCompiler = numberKeyField.compile
    end

    compileParts[#compileParts + 1] = fieldCompiler(ctx, field) .. ','
  end

  compileParts[#compileParts + 1] = '}'
  return table.concat(compileParts, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Table
