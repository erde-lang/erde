-- -----------------------------------------------------------------------------
-- Spread
-- -----------------------------------------------------------------------------

local Spread = { ruleName = 'Spread' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Spread.parse(ctx)
  if not ctx:branchStr('...') then
    ctx:throwExpected('...')
  end

  return { value = ctx:Expr() }
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Spread.compile(ctx, fields)
  local tableVar = ctx.newTmpName()
  local lenVar = ctx.newTmpName()

  local compileParts = {
    'local ' .. tableVar .. ' = {}',
    'local ' .. lenVar .. ' = 0',
  }

  for i, field in ipairs(fields) do
    if field.ruleName == Spread.ruleName then
      local spreadTmpName = ctx.newTmpName()
      compileParts[#compileParts + 1] = ctx.format(
        [[
          local %1 = %2
          for key, value in pairs(%1) do
            if type(key) == 'number' then
              %3[%4 + key] = value
            else
              %3[key] = value
            end
          end
          %4 = %4 + #%1
        ]],
        spreadTmpName,
        ctx:compile(field.value),
        tableVar,
        lenVar
      )
    elseif field.key then
      compileParts[#compileParts + 1] = ('%1[%2] = %3'):format(
        tableVar,
        field.key,
        field.value
      )
    else
      compileParts[#compileParts + 1] = ctx.format(
        [[
          %1[%2 + 1] = %3
          %2 = %2 + 1
        ]],
        tableVar,
        lenVar,
        field.value
      )
    end
  end

  return table.concat({
    '(function()',
    table.concat(compileParts, '\n'),
    'return ' .. tableVar,
    'end)()',
  }, '\n')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return Spread
