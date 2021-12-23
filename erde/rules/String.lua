-- -----------------------------------------------------------------------------
-- String
-- -----------------------------------------------------------------------------

local String = { ruleName = 'String' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function String.parse(ctx)
  local node = {}
  local capture = {}
  local terminatingStr
  local terminalBranchOpts = { pad = false }

  if ctx:branchChar("'", terminalBranchOpts) then
    node.variant = 'single'
    terminatingStr = "'"
  elseif ctx:branchChar('"', terminalBranchOpts) then
    node.variant = 'double'
    terminatingStr = '"'
  elseif ctx:branchChar('[', terminalBranchOpts) then
    local equals = {}
    ctx:stream({ ['='] = true }, equals)
    node.equals = table.concat(equals)

    if not ctx:branchChar('[', terminalBranchOpts) then
      error()
    end

    node.variant = 'long'
    terminatingStr = ']' .. node.equals .. ']'
  else
    error()
  end

  while not ctx:branchStr(terminatingStr, terminalBranchOpts) do
    if ctx.bufValue == '\\' then
      if ('{}'):find(ctx.buffer[ctx.bufIndex + 1]) then
        ctx:consume()
        ctx:consume(1, capture)
      else
        ctx:consume(2, capture)
      end
    elseif ctx.bufValue == '{' then
      if #capture > 0 then
        node[#node + 1] = table.concat(capture)
        capture = {}
      end

      node[#node + 1] = ctx:Surround('{', '}', ctx.Expr)
    elseif ctx:branchChar('\n', { pad = false, capture = capture }) then
      if node.variant ~= 'long' then
        -- Newlines only allowed in block strings
        error()
      end
    else
      ctx:consume(1, capture)
    end
  end

  if #node == 0 or #capture > 0 then
    node[#node + 1] = table.concat(capture)
  end

  return node
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function String.compile(ctx, node)
  local openingChar, closingChar

  if node.variant == 'single' then
    openingChar, closingChar = "'", "'"
  elseif node.variant == 'double' then
    openingChar, closingChar = '"', '"'
  elseif node.variant == 'long' then
    openingChar = '[' .. node.equals .. '['
    closingChar = ']' .. node.equals .. ']'
  end

  local compileParts = {}

  for i, capture in ipairs(node) do
    compileParts[#compileParts + 1] = type(capture) == 'string'
        and openingChar .. capture .. closingChar
      or 'tostring(' .. ctx:compile(capture) .. ')'
  end

  return table.concat(compileParts, '..')
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return String
