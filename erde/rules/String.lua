-- -----------------------------------------------------------------------------
-- String
-- -----------------------------------------------------------------------------

local String = { ruleName = 'String' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function String.parse(ctx)
  local node = {}
  local terminatingToken

  if ctx.token == "'" then
    node.variant = 'single'
    terminatingToken = ctx:consume()
  elseif ctx.token == '"' then
    node.variant = 'double'
    terminatingToken = ctx:consume()
  elseif ctx.token:match('^%[=*%[$') then
    node.variant = 'long'
    node.equals = ('='):rep(#ctx.token - 2)
    terminatingToken = ']' .. node.equals .. ']'
    ctx:consume()
  else
    error('Unexpected token: ' .. ctx.token)
  end

  while ctx.token ~= terminatingToken do
    if ctx.token == '{' then
      node[#node + 1] = ctx:Surround('{', '}', ctx.Expr)
    else
      node[#node + 1] = ctx:consume()
    end
  end

  ctx:consume() -- terminatingToken
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

  if #node == 0 then
    return openingChar .. closingChar
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
