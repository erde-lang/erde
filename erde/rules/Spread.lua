-- -----------------------------------------------------------------------------
-- Spread
-- -----------------------------------------------------------------------------

local Spread = { ruleName = 'Spread' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function Spread.parse(ctx)
  ctx:assert('...')
  return { value = ctx:Expr() }
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function Spread.compile(ctx, fields)
  local tableVar = ctx:newTmpName()
  local lenVar = ctx:newTmpName()

  local compileParts = {
    'local ' .. tableVar .. ' = {}',
    'local ' .. lenVar .. ' = 0',
  }

  for i, field in ipairs(fields) do
    if field.ruleName == Spread.ruleName then
      local spreadTmpName = ctx:newTmpName()
      compileParts[#compileParts + 1] = table.concat({
        'local ' .. spreadTmpName .. ' = ' .. ctx:compile(field.value),
        'for key, value in pairs(' .. spreadTmpName .. ') do',
        'if type(key) == "number" then',
        ('%s[%s + key] = value'):format(tableVar, lenVar),
        'else',
        tableVar .. '[key] = value',
        'end',
        'end',
        ('%s = %s + #%s'):format(lenVar, lenVar, spreadTmpName),
      }, '\n')
    elseif field.key then
      compileParts[#compileParts + 1] = ('%s[%s] = %s'):format(
        tableVar,
        field.key,
        field.value
      )
    else
      compileParts[#compileParts + 1] = table.concat({
        ('%s[%s + 1] = %s'):format(tableVar, lenVar, field.value),
        ('%s = %s + 1'):format(lenVar, lenVar),
      }, '\n')
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
