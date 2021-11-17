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
  if not ctx:branchStr('...') then
    ctx:throwExpected('...')
  end

  return { variant = 'spread', value = ctx:Id() }
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

local function compileTable(fields)
  return '{\n' .. table.concat(fields, ',\n') .. '\n}'
end

function Table.compile(ctx, node)
  local fieldParts = {}
  local numberKeyCount = 1
  local spreadNumberKeys = {}

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
      numberKeyCount = numberKeyCount + 1
    elseif field.variant == 'spread' then
      spreadNumberKeys[#spreadNumberKeys + 1] = numberKeyCount
      numberKeyCount = numberKeyCount + 1
    end

    if fieldCompiler then
      fieldParts[#fieldParts + 1] = fieldCompiler(ctx, field)
    end
  end

  if #spreadNumberKeys == 0 then
    return compileTable(fieldParts)
  end

  local partitionedFields = {}
  local lastPartitionEnd = 0

  for i, spreadNumberKey in ipairs(spreadNumberKeys) do
    local partition = {}

    for j = lastPartitionEnd + 1, spreadNumberKey - i do
      partition[#partition + 1] = fieldParts[j]
    end

    lastPartitionEnd = spreadNumberKey - i
    partitionedFields[i] = partition
  end

  local finalPartition = {}
  for i = lastPartitionEnd + 1, #fieldParts do
    finalPartition[#finalPartition + 1] = fieldParts[i]
  end
  partitionedFields[#partitionedFields + 1] = finalPartition

  local tableTmpName = ctx.newTmpName()
  local initTable = ('local %s = %s'):format(
    tableTmpName,
    compileTable(partitionedFields[1])
  )

  local body = {}
  for i, spreadNumberKey in ipairs(spreadNumberKeys) do
    local partition = partitionedFields[i + 1]
  end

  -- We need to fill the spreads in REVERSE order. Otherwise, subsequent spreads
  -- may no longer have the correct spreadNumberKey due to table shifting.
  return ctx.format(
    [[
      (function()
        local %1 = %2
        for i, spreadNumberKey in ipairs({}) do
          for key, value in pairs(src) do
            if type(key) == 'number' then
              table.insert(%1, spreadNumberKey, 
            else
            end
          end
        end
      end)()
    ]],
    tableTmpName,
    compiledTable
  )
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Table
