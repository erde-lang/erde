-- -----------------------------------------------------------------------------
-- Destructure
-- -----------------------------------------------------------------------------

local Destructure = { ruleName = 'Destructure' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

local function parseDestruct(ctx)
  local destruct = { name = ctx:Name().value }

  if ctx:branch(':') then
    destruct.alias = ctx:Name().value
  end

  if ctx:branch('=') then
    destruct.default = ctx:Expr()
  end

  return destruct
end

local function parseNumberKeyDestructs(ctx)
  return ctx:Surround('[', ']', function()
    return ctx:List({
      allowTrailingComma = true,
      rule = function()
        local destruct = parseDestruct(ctx)
        destruct.variant = 'numberDestruct'
        return destruct
      end,
    })
  end)
end

function Destructure.parse(ctx)
  local node = {}

  local destructs = ctx.token == '[' and parseNumberKeyDestructs(ctx)
    or ctx:Surround('{', '}', function()
      return ctx:List({
        allowTrailingComma = true,
        rule = function()
          if ctx.token == '[' then
            return parseNumberKeyDestructs(ctx)
          else
            local destruct = parseDestruct(ctx)
            destruct.variant = 'keyDestruct'
            return destruct
          end
        end,
      })
    end)

  for _, destruct in ipairs(destructs) do
    if destruct.variant ~= nil then
      table.insert(node, destruct)
    else
      for _, numberDestruct in ipairs(destruct) do
        table.insert(node, numberDestruct)
      end
    end
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Destructure.compile(ctx, node)
  local baseName = ctx:newTmpName()
  local varNames = {}
  local numberKeyCounter = 1
  local compileParts = {}

  for i, field in ipairs(node) do
    local varName = field.alias or field.name
    varNames[i] = varName

    if field.variant == 'keyDestruct' then
      table.insert(
        compileParts,
        ('%s = %s.%s'):format(varName, baseName, field.name)
      )
    elseif field.variant == 'numberDestruct' then
      table.insert(
        compileParts,
        ('%s = %s[%s]'):format(varName, baseName, numberKeyCounter)
      )
      numberKeyCounter = numberKeyCounter + 1
    end

    if field.default then
      table.insert(
        compileParts,
        ('if %s == nil then %s = %s end'):format(
          varName,
          varName,
          ctx:compile(field.default)
        )
      )
    end
  end

  table.insert(compileParts, 1, 'local ' .. table.concat(varNames, ','))

  return {
    baseName = baseName,
    compiled = table.concat(compileParts, '\n'),
  }
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Destructure
