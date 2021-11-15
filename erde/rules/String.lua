-- -----------------------------------------------------------------------------
-- String
-- -----------------------------------------------------------------------------

local String = { ruleName = 'String' }

-- -----------------------------------------------------------------------------
-- Parse
-- -----------------------------------------------------------------------------

function String.parse(ctx)
  if ctx.bufValue == "'" or ctx.bufValue == '"' then
    local capture = {}
    ctx:consume(1, capture)

    while true do
      if ctx.bufValue == capture[1] then
        ctx:consume(1, capture)
        break
      elseif ctx.bufValue == '\n' then
        ctx:throwError('Unterminated string')
      else
        ctx:consume(1, capture)
      end
    end

    return {
      variant = 'short',
      value = table.concat(capture),
    }
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
      elseif ctx.bufValue == '\\' then
        if ('{}`'):find(ctx.buffer[ctx.bufIndex + 1]) then
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
  if node.variant == 'short' then
    return node.value
  else
    local eqStr = '='
    local content = {}

    for _, capture in ipairs(node) do
      if type(capture) == 'string' and capture:find(eqStr) then
        eqStr = ('='):rep(#eqStr + 1)
      end
    end

    for _, capture in ipairs(node) do
      if type(capture) == 'string' then
        content[#content + 1] = capture
      else
        content[#content + 1] = (']%s]..tostring(%s)..[%s['):format(
          eqStr,
          ctx:compile(capture),
          eqStr
        )
      end
    end

    return ('[%s[%s]%s]'):format(eqStr, table.concat(content), eqStr)
  end
end

-- -----------------------------------------------------------------------------
-- Return
-- -----------------------------------------------------------------------------

return String
