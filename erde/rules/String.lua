local constants = require('erde.constants')

-- -----------------------------------------------------------------------------
-- String
-- -----------------------------------------------------------------------------

local String = {}

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function String.parse(ctx)
  if bufValue == "'" or bufValue == '"' then
    local capture = {}
    ctx:consume(1, capture)

    while true do
      if bufValue == capture[1] then
        ctx:consume(1, capture)
        break
      elseif bufValue == '\n' then
        ctx:throwError('Unterminated string')
      else
        ctx:consume(1, capture)
      end
    end

    return { variant = 'short', value = table.concat(capture) }
  elseif ctx:branchChar('`', true) then
    local node = { variant = 'long' }
    local capture = {}

    while true do
      if ctx:branchChar('{', true) then
        if #capture > 0 then
          node[#node + 1] = table.concat(capture)
          capture = {}
        end

        node[#node + 1] = ctx:Expr()
        if not ctx:branchChar('}', true) then
          ctx:throwExpected('}')
        end
      elseif ctx:branchChar('`', true) then
        break
      elseif bufValue == '\\' then
        if ('{}`'):find(buffer[bufIndex + 1]) then
          ctx:consume()
          ctx:consume(1, capture)
        else
          ctx:consume(2, capture)
        end
      else
        ctx:consume(1, capture)
      end
    end

    if #capture > 0 then
      node[#node + 1] = table.concat(capture)
    end

    return node
  else
    ctx:throwExpected('quote (",\',`)', true)
  end
end

-- -----------------------------------------------------------------------------
-- Compile
-- -----------------------------------------------------------------------------

function String.compile(ctx, node)
  -- TODO
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return String
