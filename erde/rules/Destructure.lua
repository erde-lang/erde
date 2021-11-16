-- -----------------------------------------------------------------------------
-- Destructure
-- -----------------------------------------------------------------------------

local Destructure = { ruleName = 'Destructure' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Destructure.parse(ctx)
  local keyCounter = 1
  local optional = ctx:branchChar('?')

  local node = ctx:Surround('{', '}', function()
    return ctx:List({
      allowEmpty = true,
      allowTrailingComma = true,
      rule = function()
        local field = {}

        if ctx:branchChar(':') then
          field.variant = 'mapDestruct'
        else
          field.variant = 'arrayDestruct'
          field.key = keyCounter
          keyCounter = keyCounter + 1
        end

        field.name = ctx:Name().value

        if ctx:branchChar('=') then
          field.default = ctx:Expr()
        end

        return field
      end,
    })
  end)

  node.optional = optional
  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Destructure.compile(ctx, node)
  local baseName = ctx.newTmpName()
  local names = {}
  local compileParts = {}

  for i, field in ipairs(node) do
    names[#names + 1] = field.name

    if field.variant == 'mapDestruct' then
      compileParts[#compileParts + 1] = ctx.format(
        '%1 = %2.%1',
        field.name,
        baseName
      )
    elseif field.variant == 'arrayDestruct' then
      compileParts[#compileParts + 1] = ctx.format(
        '%1 = %2[%3]',
        field.name,
        baseName,
        field.key
      )
    end

    if field.default then
      compileParts[#compileParts + 1] = ctx.format(
        'if %1 == nil then %1 = %2 end',
        field.name,
        ctx:compile(field.default)
      )
    end
  end

  if node.optional then
    table.insert(compileParts, 1, 'if ' .. baseName .. ' ~= nil then')
    compileParts[#compileParts + 1] = 'end'
  end

  table.insert(compileParts, 1, 'local ' .. table.concat(names, ','))

  return {
    baseName = baseName,
    compiled = table.concat(compileParts, '\n'),
  }
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Destructure
