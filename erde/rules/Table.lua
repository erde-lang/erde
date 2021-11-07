local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- Table
-- -----------------------------------------------------------------------------

local Table = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Table.parse(ctx)
  local node = { rule = 'Table' }
  local keyCounter = 1

  if not ctx:branchChar('{') then
    ctx:throwExpected('{')
  end

  while not ctx:branchChar('}') do
    local field = {}

    if ctx:branchChar(':') then
      field.variant = 'inlineKey'
      field.key = ctx:Name().value
    elseif ctx.bufValue == '[' then
      field.variant = 'exprKey'
      field.key = ctx:Surround('[', ']', ctx.Expr)

      if not ctx:branchChar(':') then
        ctx:throwExpected(':')
      end

      field.value = ctx:Expr()
    else
      local expr = ctx:Switch({
        ctx.Name,
        ctx.Expr,
      })

      if not expr then
        ctx:throwUnexpected()
      end

      if not ctx:branchChar(':') then
        field.variant = 'arrayKey'
        field.key = keyCounter
        field.value = expr
        keyCounter = keyCounter + 1
      elseif expr.rule == 'Name' then
        field.variant = 'nameKey'
        field.key = expr.value
        field.value = ctx:Expr()
      elseif expr.rule == 'String' then
        field.variant = 'stringKey'
        field.key = expr
        field.value = ctx:Expr()
      else
        ctx:throwUnexpected('expression')
      end
    end

    node[#node + 1] = field

    if not ctx:branchChar(',') and ctx.bufValue ~= '}' then
      ctx:throwError('Missing comma')
    end
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Table.compile(ctx, node)
  local compileParts = { '{' }

  for i, field in ipairs(node) do
    if field.variant == 'arrayKey' then
      compileParts[#compileParts + 1] = ctx.format(
        '%1,',
        ctx:compile(field.value)
      )
    elseif field.variant == 'inlineKey' then
      compileParts[#compileParts + 1] = ctx.format('%1 = %1,', field.key)
    elseif field.variant == 'exprKey' then
      compileParts[#compileParts + 1] = ctx.format(
        -- Space around brackets to avoid long string expressions
        -- [ [=[some string]=] ]
        '[ %1 ] = %2,',
        ctx:compile(field.key),
        ctx:compile(field.value)
      )
    elseif field.variant == 'nameKey' then
      compileParts[#compileParts + 1] = ctx.format(
        '%1 = %2,',
        field.key,
        ctx:compile(field.value)
      )
    elseif field.variant == 'stringKey' then
      compileParts[#compileParts + 1] = ctx.format(
        -- Space around brackets to avoid long string expressions
        -- [ [=[some string]=] ]
        '[ %1 ] = %2,',
        ctx:compile(field.key),
        ctx:compile(field.value)
      )
    end
  end

  compileParts[#compileParts + 1] = '}'
  return table.concat(compileParts, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Table
