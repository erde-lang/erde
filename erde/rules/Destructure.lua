-- -----------------------------------------------------------------------------
-- Destructure
-- -----------------------------------------------------------------------------

local Destructure = { ruleName = 'Destructure' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

local function parseDestruct(ctx)
  local destruct = { name = ctx:Name().value }

  -- TODO: parse alias here

  if ctx:branchChar('=') then
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
  local node = { optional = ctx:branchChar('?') }

  local destructs = ctx:Switch({
    parseNumberKeyDestructs,
    function()
      return ctx:Surround('{', '}', function()
        return ctx:List({
          allowTrailingComma = true,
          rule = function()
            return ctx:Switch({
              parseNumberKeyDestructs,
              function()
                local destruct = parseDestruct(ctx)
                destruct.variant = 'keyDestruct'
                return destruct
              end,
            })
          end,
        })
      end)
    end,
  })

  if not destructs then
    ctx:throwUnexpected()
  end

  for i, destruct in ipairs(destructs) do
    if destruct.variant ~= nil then
      node[#node + 1] = destruct
    else
      for i, numberDestruct in ipairs(destruct) do
        node[#node + 1] = numberDestruct
      end
    end
  end

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

    if field.variant == 'keyDestruct' then
      compileParts[#compileParts + 1] = ctx.format(
        '%1 = %2.%1',
        field.name,
        baseName
      )
    elseif field.variant == 'numberDestruct' then
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
